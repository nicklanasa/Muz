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
NSFetchedResultsControllerDelegate,
ArtistAlbumHeaderDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    lazy var artistsController: NSFetchedResultsController = {
        var predicate = NSPredicate(format: "name = %@", self.artist.name)
        let controller = DataManager.manager.datastore.artistsController(predicate,
            sortKey: "name",
            ascending: true,
            sectionNameKeyPath: nil)
        controller.delegate = self
        return controller
    }()
    
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
    
    override init() {
        super.init(nibName: "ArtistAlbumsViewController", bundle: nil)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
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

        }
    }
    
    // MARK: Sectors NSFetchedResultsControllerDelegate
    
    func controllerWillChangeContent(controller: NSFetchedResultsController)
    {
        self.tableView.beginUpdates()
    }
    
    func controller(controller: NSFetchedResultsController,
        didChangeObject anObject: AnyObject,
        atIndexPath indexPath: NSIndexPath?,
        forChangeType type: NSFetchedResultsChangeType,
        newIndexPath: NSIndexPath?)
    {
        if let albumArtist = self.artistsController.objectAtIndexPath(NSIndexPath(forRow: 0, inSection: 0)) as? Artist {
            var indexPaths = NSMutableArray()
            var section = 0
            for album in albumArtist.albums.allObjects as [Album] {
                indexPaths.addObject(NSIndexPath(forRow: 0, inSection: section))
                section++
            }
            
            self.tableView.reloadSections(NSIndexSet(indexesInRange: NSMakeRange(0, section)),
                withRowAnimation: .Fade)
        }
    }
    
    func controller(controller: NSFetchedResultsController,
        didChangeSection sectionInfo: NSFetchedResultsSectionInfo,
        atIndex sectionIndex: Int,
        forChangeType type: NSFetchedResultsChangeType)
    {
        switch type {
            
        case .Insert:
            self.tableView.insertSections(NSIndexSet(index: sectionIndex),
                withRowAnimation: .Fade)
            
        case .Delete:
            self.tableView.deleteSections(NSIndexSet(index: sectionIndex),
                withRowAnimation: .Fade)
            
        case .Update, .Move: println("Move or delete called in didChangeSection")
        }
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController)
    {
        self.tableView.endUpdates()
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
            forIndexPath: indexPath) as ArtistAlbumsSongCell
        if let albumArtist = self.artistsController.objectAtIndexPath(NSIndexPath(forRow: 0, inSection: 0)) as? Artist {
            if let album = albumArtist.albums.allObjects[indexPath.section] as? Album {
                if let song = album.songs.allObjects[indexPath.row] as? Song {
                    cell.configure(song: song)
                }
            }
        }
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
                let header = tableView.dequeueReusableHeaderFooterViewWithIdentifier("Header") as ArtistAlbumHeader
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
        if let albumArtist = self.artistsController.objectAtIndexPath(NSIndexPath(forRow: 0, inSection: 0)) as? Artist {
            if let album = albumArtist.albums.allObjects[indexPath.section] as? Album {
                if let song = album.songs.allObjects[indexPath.row] as? Song {
                    DataManager.manager.fetchCollectionForAlbum(album: album, completion: { (collection, error) -> () in
                        self.presentNowPlayViewController(song, collection: collection)
                    })
                }
            }
        }
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        
    }
    
    func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [AnyObject]? {
        let addToPlaylistAction = UITableViewRowAction(style: UITableViewRowActionStyle.Default, title: "Add to Playlist", handler: { (action, indexPath) -> Void in
            if let albumArtist = self.artistsController.objectAtIndexPath(NSIndexPath(forRow: 0, inSection: 0)) as? Artist {
                if let album = albumArtist.albums.allObjects[indexPath.section] as? Album {
                    if let song = album.songs.allObjects[indexPath.row] as? Song {
                        let createPlaylistOverlay = CreatePlaylistOverlay(songs: [song])
                        self.presentModalOverlayController(createPlaylistOverlay, blurredController: self)
                    }
                }
            }
        })
        
        return [addToPlaylistAction]
    }
    
    // MARK: ArtistAlbumHeaderDelegate
    
    func artistAlbumHeader(header: ArtistAlbumHeader, moreButtonTapped sender: AnyObject) {
        let header = tableView.headerViewForSection(header.section) as ArtistAlbumHeader
        if let albumArtist = self.artistsController.objectAtIndexPath(NSIndexPath(forRow: 0, inSection: 0)) as? Artist {
            if let album = albumArtist.albums.allObjects[header.section] as? Album {
                let createPlaylistOverlay = CreatePlaylistOverlay(songs: album.songs.allObjects)
                self.presentModalOverlayController(createPlaylistOverlay, blurredController: self)
            }
        }
    }
}