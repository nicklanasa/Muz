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
    var songs: NSArray?
    var songsQuery: MPMediaQuery?
    var songsSections = NSMutableArray()
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    override init() {
        super.init(nibName: "SongsViewController", bundle: nil)
        
        self.tabBarItem = UITabBarItem(title: nil,
            image: UIImage(named: "songs"),
            selectedImage: UIImage(named: "songs"))
        self.tabBarItem.imageInsets = UIEdgeInsetsMake(6, 0, -6, 0)
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
        
        fetchSongs()
                
        self.navigationItem.title = "Songs"
    }
    
    func fetchSongs() {
        
        songsQuery = MPMediaQuery.songsQuery()
        songs = songsQuery?.items
        
        if let query = songsQuery {
            for section in query.itemSections {
                if let songSection = section as? MPMediaQuerySection {
                    songsSections.addObject(songSection.title)
                }
            }
        }
        
        self.activityIndicator.stopAnimating()
        self.tableView.reloadData()
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return songsQuery?.itemSections.count ?? 0
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let section = songsQuery?.itemSections[section] as? MPMediaQuerySection
        return section?.range.length ?? 0
    }
    
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if let section = songsQuery?.itemSections[section] as? MPMediaQuerySection {
            let header = tableView.dequeueReusableHeaderFooterViewWithIdentifier("Header") as SongsHeader
            header.infoLabel.text = section.title
            return header
        } else {
            return nil
        }
    }
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 30
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell",
            forIndexPath: indexPath) as SongCell

        let section = self.songsQuery?.itemSections[indexPath.section] as MPMediaQuerySection
        
        if let song = songs?[indexPath.row + section.range.location] as? MPMediaItem {
            cell.songLabel.text = song.title
            cell.infoLabel.text = song.artist
            cell.infoLabel.text = NSString(format: "%@ %@", cell.infoLabel.text!, song.albumTitle)
            
            if let artwork = song.artwork {
                cell.songImageView?.image = song.artwork.imageWithSize(cell.songImageView.frame.size)
            } else {
                cell.songImageView?.image = UIImage(named: "noArtwork")
            }
            
        }
    
        return cell
    }
    
    func sectionIndexTitlesForTableView(tableView: UITableView) -> [AnyObject]! {
        return songsSections
    }
    
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        // Get song.
        let section = self.songsQuery?.itemSections[indexPath.section] as MPMediaQuerySection
        if let song = songs?[indexPath.row + section.range.location] as? MPMediaItem {
            presentNowPlayViewControllerWithItem(song)
        }        
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
