//
//  ArtistAlbumsViewController.swift
//  Muz
//
//  Created by Nick Lanasa on 12/10/14.
//  Copyright (c) 2014 Nytek Productions. All rights reserved.
//

import Foundation
import UIKit
import CoreData
import MediaPlayer

class ArtistAlbumsViewController: RootViewController,
    UITableViewDelegate,
    UITableViewDataSource,
    ArtistAlbumHeaderDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var sortedSongs = NSMutableArray()
    
    lazy var artistsController: NSFetchedResultsController = {
        var predicate = NSPredicate(format: "name = %@", self.artist.name)
        let controller = DataManager.manager.datastore.artistsController(predicate,
            sortKey: "name",
            ascending: true,
            sectionNameKeyPath: nil)
        return controller
    }()
    
    lazy var formatter: DateFormatter = {
        var formatter = DateFormatter()
        formatter.dateFormat = "mm:ss"
        return formatter
    }()
    
    let artist: Artist!
    
    init(artist: Artist) {
        self.artist = artist
        super.init(nibName: "ArtistAlbumsViewController", bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(UINib(nibName: "ArtistAlbumsSongCell", bundle: nil), forCellReuseIdentifier: "Cell")
        tableView.register(UINib(nibName: "ArtistAlbumHeader", bundle: nil), forHeaderFooterViewReuseIdentifier: "Header")
    
        fetchArtistAlbums()
    }
    
    func artistInfo() {
        let controller = NowPlayingInfoViewController(artist: self.artist.name as NSString, isForSimiliarArtist: true)
        self.navigationController?.pushViewController(controller, animated: true)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.title = self.artist.name
        super.viewWillAppear(animated)
        self.tableView.setEditing(false, animated: true)
    }
    
    /**
    Fetch albums for artist.
    */
    fileprivate func fetchArtistAlbums() {
        do {
            try self.artistsController.performFetch()
            if let albumArtist = self.artistsController.object(at: IndexPath(row: 0, section: 0)) as? Artist {
                let albums = NSArray(array: albumArtist.albums.allObjects)
                let sort = NSSortDescriptor(key: "albumTrackNumber", ascending: true)
                
                for album in albums {
                    if let artistAlbum = album as? Album {
                        let songs = NSMutableArray(array: artistAlbum.songs.allObjects)
                        self.sortedSongs.add(songs.sortedArray(using: [sort]))
                    }
                }
            }
        } catch { }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let albumArtist = self.artistsController.object(at: IndexPath(row: 0, section: 0)) as? Artist {
            if let album = albumArtist.albums.allObjects[section] as? Album {
                return album.songs.count
            }
        }
        return 0
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if let albumArtist = self.artistsController.object(at: IndexPath(row: 0, section: 0)) as? Artist {
            return albumArtist.albums.count
        }
        
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell",
            for: indexPath) as! ArtistAlbumsSongCell
        if let songs = self.sortedSongs[indexPath.section] as? [AnyObject] {
            if let song = songs[indexPath.row] as? Song {
                cell.configure(song: song)
            }
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 75
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if tableView == self.searchDisplayController?.searchResultsTableView {
            return nil
        }
        
        if let albumArtist = self.artistsController.object(at: IndexPath(row: 0, section: 0)) as? Artist {
            if let album = albumArtist.albums.allObjects[section] as? Album {
                let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: "Header") as! ArtistAlbumHeader
                header.updateWithAlbum(album: album)
                header.section = section
                header.delegate = self
                return header
            }
        }
        
        return nil
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Get song.    
        if let songs = self.sortedSongs[indexPath.section] as? [AnyObject] {
            if let song = songs[indexPath.row] as? Song {
                DataManager.manager.fetchCollectionForArtist(artist: song.artist, completion: { (collection, error) -> () in
                    if collection != nil {
                        self.presentNowPlayViewController(song, collection: collection!)
                    } else {
                        DispatchQueue.main.async(execute: { () -> Void in
                            UIAlertView(title: "Error!",
                                message: "Unable to get collection!",
                                delegate: self,
                                cancelButtonTitle: "Ok").show()
                        })
                    }
                })
            }
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let addAction = UITableViewRowAction(style: .normal, title: "Add to playlist") { (action, indexPath) -> Void in
            if let songs = self.sortedSongs[indexPath.section] as? [AnyObject] {
                if let song = songs[indexPath.row] as? Song {
                    let createPlaylistOverlay = CreatePlaylistOverlay(songs: [song])
                    self.presentModalOverlayController(createPlaylistOverlay, blurredController: self)
                }
            }
        }
        
        return [addAction]
    }
    
    // MARK: ArtistAlbumHeaderDelegate
    
    func artistAlbumHeader(_ header: ArtistAlbumHeader, moreButtonTapped sender: AnyObject) {
        let header = tableView.headerView(forSection: header.section) as! ArtistAlbumHeader
        if let songs = self.sortedSongs[header.section] as? [AnyObject] {
            let createPlaylistOverlay = CreatePlaylistOverlay(songs: songs)
            self.presentModalOverlayController(createPlaylistOverlay, blurredController: self)
        }
    }
}
