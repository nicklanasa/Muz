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

extension NSString {
    func stringByGroupingByFirstLetter() -> NSString {
        if self.length == 0 || self.length == 1 {
            return self
        } else {
            return self.substringToIndex(1)
        }
    }
}

class ArtistsViewController: RootViewController,
UITableViewDelegate,
UITableViewDataSource,
NSFetchedResultsControllerDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    // The NSFetchedResultsController used to pull tasks for the selected date.
    var artists: [AnyObject]?
    var artistsController: NSFetchedResultsController!
    var artistsCollections: NSArray!
    var artistsImages = NSMutableDictionary()
    
    override init() {
        super.init(nibName: "ArtistsViewController", bundle: nil)
        
        self.tabBarItem = UITabBarItem(title: "Artists",
            image: UIImage(named: "artists"),
            selectedImage: UIImage(named: "artists"))
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.registerNib(UINib(nibName: "ArtistCell", bundle: nil), forCellReuseIdentifier: "Cell")
        
        /*
        MediaSession.sharedSession.openSessionWithCompletionBlock { (success) -> () in
            self.fetchArtists()
        }
        */
        
        fetchArtists()
        self.navigationItem.title = "Artists"
    }
    
    func fetchArtists() {
        
        artistsController = MediaSession.sharedSession.dataManager.datastore.artistsControllerWithSortKey("artist",
            ascending: true,
            sectionNameKeyPath: "artist.stringByGroupingByFirstLetter")
        
        var error: NSError?
        if artistsController.performFetch(&error) {
            
            artistsCollections = MediaSession.sharedSession.artworkForArtists()
            
            for artistCollection in artistsCollections {
                if let collection = artistCollection as? MPMediaItemCollection {
                    for artistItem in collection.items {
                        if let item = artistItem as? MPMediaItem {
                            if let artwork = item.valueForProperty(MPMediaItemPropertyArtwork) as? MPMediaItemArtwork {
                                if let image = artwork.imageWithSize(CGSizeMake(40, 40)) {
                                    self.artistsImages.setObject(image, forKey: item.artist)
                                    break
                                }
                            }
                        }
                    }
                }
            }
            
            self.tableView.reloadData()
            self.activityIndicator.stopAnimating()
        }
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return artistsController.sections?.count ?? 0
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionInfo = artistsController.sections![section] as NSFetchedResultsSectionInfo
        return sectionInfo.numberOfObjects
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell",
            forIndexPath: indexPath) as ArtistCell
        let song = artistsController.objectAtIndexPath(indexPath) as NSDictionary
        let artist = song.objectForKey("artist") as NSString
        cell.artistLabel.text = artist
        if let image = artistsImages.objectForKey(artist) as? UIImage {
            cell.artistImageView.image = image
        } else {
            cell.artistImageView.image = UIImage(named: "noArtwork")
        }
        
        return cell
    }
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 30
    }
    
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        let sectionInfo = artistsController.sections![section] as NSFetchedResultsSectionInfo
        
        let header = UIView(frame: CGRectMake(0, 0, 320, 30))
        header.backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(0.2)
        header.autoresizingMask = .FlexibleWidth
        
        var label = UILabel(frame: CGRectMake(5, 5, 200, 25))
        label.autoresizingMask = .FlexibleWidth
        label.text = sectionInfo.name
        label.textColor = UIColor.whiteColor()
        header.addSubview(label)
        
        return header
    }
    
    func sectionIndexTitlesForTableView(tableView: UITableView) -> [AnyObject]! {
        return artistsController.sectionIndexTitles
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
