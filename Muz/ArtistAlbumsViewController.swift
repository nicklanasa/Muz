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
NSFetchedResultsControllerDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var albums: NSArray?
    var albumsQuery: MPMediaQuery?
    var albumsSections = NSMutableArray()
    
    var fetchedObjects: [AnyObject]?
    
    lazy var formatter: NSDateFormatter = {
        var formatter = NSDateFormatter()
        formatter.dateFormat = "mm:ss"
        return formatter
    }()
    
    // The NSFetchedResultsController used to pull tasks for the selected date.
    var artists: [AnyObject]?
    var artistsAlbumsController: NSFetchedResultsController!
    
    let artist: NSString!
    
    init(artist: NSString) {
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
        self.navigationItem.title = "Albums"
    }
    
    func fetchArtistAlbums() {
        
        let artistPredicate = MPMediaPropertyPredicate(value: artist, forProperty: MPMediaItemPropertyArtist, comparisonType: .EqualTo)
        albumsQuery = MPMediaQuery.albumsQuery()
        albumsQuery?.addFilterPredicate(artistPredicate)
        
        albums = albumsQuery?.collections
        
        if let query = albumsQuery {
            for section in query.collectionSections {
                if let songSection = section as? MPMediaQuerySection {
                    albumsSections.addObject(songSection.title)
                }
            }
        }
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return albums?.count ?? 0
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let section = albums?[section] as? MPMediaItemCollection
        return section?.items.count ?? 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell",
            forIndexPath: indexPath) as ArtistAlbumsSongCell
                
        if let songs = albums?[indexPath.section] as? MPMediaItemCollection {
            if let song = songs.items[indexPath.row] as? MPMediaItem {
                cell.songLabel.text = song.title
                let min = floor(song.playbackDuration / 60)
                let sec = floor(song.playbackDuration - (min * 60))
                cell.infoLabel.text = NSString(format: "%.0f:%@%.0f", min, sec < 10 ? "0" : "", sec)
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
        
        if let section = albums?[section] as? MPMediaItemCollection {
            let header = tableView.dequeueReusableHeaderFooterViewWithIdentifier("Header") as ArtistAlbumHeader
            header.updateWithItem(section.representativeItem)
            return header
        } else {
            return nil
        }
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        // Get song.        
        if let songs = albums?[indexPath.section] as? MPMediaItemCollection {
            if let song = songs.items[indexPath.row] as? MPMediaItem {
                presentNowPlayViewControllerWithItem(song)
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
        let addToPlaylistAction = UITableViewRowAction(style: UITableViewRowActionStyle.Normal, title: "Add to Playlist", handler: { (action, indexPath) -> Void in
            
        })
        
        return [addToPlaylistAction]
    }
}