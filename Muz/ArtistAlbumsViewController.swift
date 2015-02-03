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
            DataManager.manager.syncArtists({ (addedItems, error) -> () in
                
            })
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
        var tableView = self.tableView
        var indexPaths:[NSIndexPath] = [NSIndexPath]()
        switch type {
            
        case .Insert:
            indexPaths.append(newIndexPath!)
            tableView.insertRowsAtIndexPaths(indexPaths, withRowAnimation: .Fade)
            
        case .Delete:
            indexPaths.append(indexPath!)
            tableView.deleteRowsAtIndexPaths(indexPaths, withRowAnimation: .Fade)
            
        case .Update:
            indexPaths.append(indexPath!)
            tableView.reloadRowsAtIndexPaths(indexPaths, withRowAnimation: .Fade)
            
        case .Move:
            indexPaths.append(indexPath!)
            tableView.deleteRowsAtIndexPaths(indexPaths, withRowAnimation: .Fade)
            indexPaths.removeAtIndex(0)
            indexPaths.append(newIndexPath!)
            tableView.insertRowsAtIndexPaths(indexPaths, withRowAnimation: .Fade)
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
        if let albumArtist = self.artistsController.objectAtIndexPath(NSIndexPath(forRow: 0, inSection: section)) as? Artist {
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
        
        let album = self.artistsController.objectAtIndexPath(indexPath) as Album
        cell.songLabel.text = album.title
        
        if let song = album.songs.allObjects[indexPath.row] as? Song {
            let min = floor(song.playbackDuration.floatValue / 60)
            let sec = floor(song.playbackDuration.floatValue - (min * 60))
            cell.infoLabel.text = NSString(format: "%.0f:%@%.0f", min, sec < 10 ? "0" : "", sec)
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
        
        if let albumArtist = self.artistsController.objectAtIndexPath(NSIndexPath(forRow: 0, inSection: section)) as? Artist {
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
//        if let songs = albums?[indexPath.section] as? MPMediaItemCollection {
//            if let song = songs.items[indexPath.row] as? MPMediaItem {
//                presentNowPlayViewControllerWithItem(song)
//            }
//        }
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        
    }
    
    func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [AnyObject]? {
        let addToPlaylistAction = UITableViewRowAction(style: UITableViewRowActionStyle.Default, title: "Add to Playlist", handler: { (action, indexPath) -> Void in
//            if let songs = self.albums?[indexPath.section] as? MPMediaItemCollection {
//                if let song = songs.items[indexPath.row] as? MPMediaItem {
//                    let createPlaylistOverlay = CreatePlaylistOverlay(items: [song])
//                    self.presentModalOverlayController(createPlaylistOverlay, blurredController: self)
//                }
//            }
        })
        
        return [addToPlaylistAction]
    }
    
    // MARK: ArtistAlbumHeaderDelegate
    
    func artistAlbumHeader(header: ArtistAlbumHeader, moreButtonTapped sender: AnyObject) {
//        let header = tableView.headerViewForSection(header.section) as ArtistAlbumHeader
//        if let songs = albums?[header.section] as? MPMediaItemCollection {
//            let items = songs.items as [MPMediaItem]
//            let createPlaylistOverlay = CreatePlaylistOverlay(items: items)
//            presentModalOverlayController(createPlaylistOverlay, blurredController: self)
//        }
    }
}