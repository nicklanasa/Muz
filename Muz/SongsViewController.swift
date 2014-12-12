//
//  ArtistsViewController.swift
//  Muz
//
//  Created by Nick Lanasa on 12/7/14.
//
//

import Foundation
import UIKit
import CoreData
import MediaPlayer

class SongsViewController: RootViewController,
UITableViewDelegate,
UITableViewDataSource,
NSFetchedResultsControllerDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    // The NSFetchedResultsController used to pull tasks for the selected date.
    var songs: NSArray!
    var songsController: NSFetchedResultsController!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    override init() {
        super.init(nibName: "SongsViewController", bundle: nil)
        
        self.tabBarItem = UITabBarItem(title: "Songs",
            image: UIImage(named: "songs"),
            selectedImage: UIImage(named: "songs"))
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.registerNib(UINib(nibName: "SongCell", bundle: nil), forCellReuseIdentifier: "Cell")
        tableView.registerNib(UINib(nibName: "SongsHeader", bundle: nil), forHeaderFooterViewReuseIdentifier: "Header")
        tableView.alpha = 0.0
        
        fetchSongs()
                
        self.navigationItem.title = "Songs"
    }
    
    func fetchSongs() {
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.songsController = MediaSession.sharedSession.dataManager.datastore.songsControllerWithSortKey("title",
                ascending: true,
                sectionNameKeyPath: "title.stringByGroupingByFirstLetter")
            
            var error: NSError?
            if self.songsController.performFetch(&error) {
                self.tableView.alpha = 1.0
                self.activityIndicator.stopAnimating()
                self.tableView.reloadData()
            }
        })
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if let controller = songsController {
            return songsController.sections?.count ?? 0
        }
        return 0
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let controller = songsController {
            let sectionInfo = songsController.sections![section] as NSFetchedResultsSectionInfo
            return sectionInfo.numberOfObjects
        }
        
        return 0
    }
    
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let sectionInfo = songsController.sections![section] as NSFetchedResultsSectionInfo
        
        let header = tableView.dequeueReusableHeaderFooterViewWithIdentifier("Header") as SongsHeader
        
        header.infoLabel.text = sectionInfo.name
        
        return header
    }
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 30
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell",
            forIndexPath: indexPath) as SongCell
        let song = songsController.objectAtIndexPath(indexPath) as NSDictionary
        cell.songLabel.text = song.objectForKey("title") as NSString
        
        if let artist = song.objectForKey("artist") as? NSString {
            cell.infoLabel.text = NSString(format: "%@", artist)
        }
        
        if let album = song.objectForKey("albumTitle") as? NSString {
            cell.infoLabel.text = NSString(format: "%@ %@", cell.infoLabel.text!, album)
        }
        
        return cell
    }
    
    func sectionIndexTitlesForTableView(tableView: UITableView) -> [AnyObject]! {
        if let controller = songsController {
            return songsController.sectionIndexTitles
        }
        return []
    }
    
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        // Get song.
        let songInfo = songsController.objectAtIndexPath(indexPath) as NSDictionary
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
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        searchBar.resignFirstResponder()
    }
}
