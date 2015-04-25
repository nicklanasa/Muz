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
    ArtistAlbumHeaderDelegate,
SWTableViewCellDelegate  {
    
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
    
    var leftSwipeButtons: NSArray {
        get {
            
            var buttons = NSMutableArray()
            
            buttons.sw_addUtilityButtonWithColor(UIColor.clearColor(), icon: UIImage(named: "addWhite"))
            
            return buttons
        }
    }
    
    lazy var formatter: NSDateFormatter = {
        var formatter = NSDateFormatter()
        formatter.dateFormat = "mm:ss"
        return formatter
    }()
    
    let artist: Artist!
    
    init(artist: Artist) {
        self.artist = artist
        super.init(nibName: "ArtistAlbumsViewController", bundle: nil)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.registerNib(UINib(nibName: "ArtistAlbumsSongCell", bundle: nil), forCellReuseIdentifier: "Cell")
        tableView.registerNib(UINib(nibName: "ArtistAlbumHeader", bundle: nil), forHeaderFooterViewReuseIdentifier: "Header")
    
        fetchArtistAlbums()
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "info"),
            style: .Plain,
            target: self,
            action: "artistInfo")
    }
    
    func artistInfo() {
        var controller = NowPlayingInfoViewController(artist: self.artist.name, isForSimiliarArtist: true)
        self.navigationController?.pushViewController(controller, animated: true)
    }
    
    override func viewDidAppear(animated: Bool) {
        self.screenName = "Albums"
        super.viewWillAppear(animated)
        self.tableView.setEditing(false, animated: true)
    }
    
    /**
    Fetch albums for artist.
    */
    private func fetchArtistAlbums() {
        var error: NSError?
        if self.artistsController.performFetch(&error) {
            if let albumArtist = self.artistsController.objectAtIndexPath(NSIndexPath(forRow: 0, inSection: 0)) as? Artist {
                var albums = NSArray(array: albumArtist.albums.allObjects)
                var sort = NSSortDescriptor(key: "albumTrackNumber", ascending: true)
                
                for album in albums {
                    if let artistAlbum = album as? Album {
                        var songs = NSMutableArray(array: artistAlbum.songs.allObjects)
                        self.sortedSongs.addObject(songs.sortedArrayUsingDescriptors([sort]))
                    }
                }
            }
        }
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let albumArtist = self.artistsController.objectAtIndexPath(NSIndexPath(forRow: 0, inSection: 0)) as? Artist {
            if let album = albumArtist.albums.allObjects[section] as? Album {
                return album.songs.count
            }
        }
        return 0
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if let albumArtist = self.artistsController.objectAtIndexPath(NSIndexPath(forRow: 0, inSection: 0)) as? Artist {
            return albumArtist.albums.count
        }
        
        return 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell",
            forIndexPath: indexPath) as! ArtistAlbumsSongCell
        if let songs = self.sortedSongs[indexPath.section] as? [AnyObject] {
            if let song = songs[indexPath.row] as? Song {
                cell.configure(song: song)
            }
        }
        
        cell.delegate = self
        cell.leftUtilityButtons = self.leftSwipeButtons as [AnyObject]
        
        return cell
    }
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 75
    }
    
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if tableView == self.searchDisplayController?.searchResultsTableView {
            return nil
        }
        
        if let albumArtist = self.artistsController.objectAtIndexPath(NSIndexPath(forRow: 0, inSection: 0)) as? Artist {
            if let album = albumArtist.albums.allObjects[section] as? Album {
                let header = tableView.dequeueReusableHeaderFooterViewWithIdentifier("Header") as! ArtistAlbumHeader
                header.updateWithAlbum(album: album)
                header.section = section
                header.delegate = self
                return header
            }
        }
        
        return nil
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        // Get song.    
        if let songs = self.sortedSongs[indexPath.section] as? [AnyObject] {
            if let song = songs[indexPath.row] as? Song {
                DataManager.manager.fetchCollectionForArtist(artist: song.artist, completion: { (collection, error) -> () in
                    self.presentNowPlayViewController(song, collection: collection)
                })
            }
        }
        
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    func swipeableTableViewCell(cell: SWTableViewCell!, didTriggerLeftUtilityButtonWithIndex index: Int) {
        var indexPath = self.tableView.indexPathForCell(cell)!
        if let songs = self.sortedSongs[indexPath.section] as? [AnyObject] {
            if let song = songs[indexPath.row] as? Song {
                let createPlaylistOverlay = CreatePlaylistOverlay(songs: [song])
                self.presentModalOverlayController(createPlaylistOverlay, blurredController: self)
            }
        }
    }
    
    // MARK: ArtistAlbumHeaderDelegate
    
    func artistAlbumHeader(header: ArtistAlbumHeader, moreButtonTapped sender: AnyObject) {
        let header = tableView.headerViewForSection(header.section) as! ArtistAlbumHeader
        if let songs = self.sortedSongs[header.section] as? [AnyObject] {
            let createPlaylistOverlay = CreatePlaylistOverlay(songs: songs)
            self.presentModalOverlayController(createPlaylistOverlay, blurredController: self)
        }
    }
}