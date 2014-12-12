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
        tableView.registerNib(UINib(nibName: "ArtistAlbumsAlbumHeader", bundle: nil), forHeaderFooterViewReuseIdentifier: "Header")
    
        fetchArtistAlbums()
        self.navigationItem.title = "Albums"
    }
    
    func fetchArtistAlbums() {
        
        artistsAlbumsController = MediaSession.sharedSession.dataManager.datastore.artistsAlbumsControllerWithSortKey(artist,
            sortKey: "albumTitle",
            ascending: true,
            sectionNameKeyPath: "albumTitle")
        
        var error: NSError?
        if artistsAlbumsController.performFetch(&error) {
            self.tableView.reloadData()
            self.activityIndicator.stopAnimating()
      
        }
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return artistsAlbumsController.sections?.count ?? 0
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionInfo = artistsAlbumsController.sections![section] as NSFetchedResultsSectionInfo
        return sectionInfo.numberOfObjects
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell",
            forIndexPath: indexPath) as ArtistAlbumsSongCell
        let song = artistsAlbumsController.objectAtIndexPath(indexPath) as NSDictionary
        cell.songLabel.text = song.objectForKey("title") as NSString
        
        if let duration = song.objectForKey("playbackDuration") as? Float {
            let min = floor(duration / 60)
            let sec = floor(duration - (min * 60))
            cell.infoLabel.text = NSString(format: "%.0f:%@%.0f", min, sec < 10 ? "0" : "", sec)
        }
        
        return cell
    }
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 75
    }
    
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        let sectionInfo = artistsAlbumsController.sections![section] as NSFetchedResultsSectionInfo
        
        let song = artistsAlbumsController.objectAtIndexPath(NSIndexPath(forRow: 0, inSection: section)) as NSDictionary
        
        let header = tableView.dequeueReusableHeaderFooterViewWithIdentifier("Header") as ArtistAlbumsAlbumHeader
        header.updateWithData(song)
        
        header.infoLabel.text = NSString(format: "%d tracks", sectionInfo.numberOfObjects)
        
        return header
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        // Get song.
        let songInfo = artistsAlbumsController.objectAtIndexPath(indexPath) as NSDictionary
        presentNowPlayViewControllerWithSongInfo(songInfo)
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        
    }
    
    func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [AnyObject]? {
        let deleteAction = UITableViewRowAction(style: UITableViewRowActionStyle.Default, title: "Delete", handler: { (action, indexPath) -> Void in
            
        })
        
        let addToPlaylistAction = UITableViewRowAction(style: UITableViewRowActionStyle.Normal, title: "Add to Playlist", handler: { (action, indexPath) -> Void in
            
        })
        
        return [deleteAction, addToPlaylistAction]
    }
}