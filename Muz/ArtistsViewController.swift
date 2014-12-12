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
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    // The NSFetchedResultsController used to pull tasks for the selected date.
    var artists: [AnyObject]?
    var artistsController: NSFetchedResultsController!
    var artistsCollections: NSArray!
    var artistsInfo = NSMutableDictionary()
    
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
        tableView.registerNib(UINib(nibName: "ArtistsHeader", bundle: nil), forHeaderFooterViewReuseIdentifier: "Header")
        
//        MediaSession.sharedSession.openSessionWithCompletionBlock { (success) -> () in
//            self.fetchArtists()
//        }

        
        fetchArtists()
        self.navigationItem.title = "Artists"
    }
    
    func fetchArtists() {
        
        artistsController = MediaSession.sharedSession.dataManager.datastore.artistsControllerWithSortKey("artist",
            ascending: true,
            sectionNameKeyPath: "artist.stringByGroupingByFirstLetter")
        
        var error: NSError?
        if artistsController.performFetch(&error) {
            
            artistsCollections = MediaSession.sharedSession.infoForArtists()
            var albumCounter = NSCountedSet()
            
            for albumCollection in artistsCollections {
                if let collection = albumCollection as? MPMediaItemCollection {
                    var artistInfo = NSMutableDictionary()
                    let repItem = collection.representativeItem
                    albumCounter.addObject(repItem.valueForProperty(MPMediaItemPropertyArtist))
                    
                    for artistItem in collection.items {
                        if let item = artistItem as? MPMediaItem {
                            if let artwork = item.valueForProperty(MPMediaItemPropertyArtwork) as? MPMediaItemArtwork {
                                if let image = artwork.imageWithSize(CGSizeMake(40, 40)) {
                                    artistInfo.setObject(image, forKey: "artwork")
                                    break
                                }
                            }
                        }
                    }
                    
                    artistInfo.setObject(NSNumber(integer: albumCounter.countForObject(repItem.valueForProperty(MPMediaItemPropertyArtist))), forKey: "albumCount")
                    
                    artistsInfo.setObject(artistInfo, forKey: repItem.artist)
                }
            }
            
            self.tableView.reloadData()
            self.activityIndicator.stopAnimating()
        }
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if let controller = artistsController {
            return artistsController.sections?.count ?? 0
        }
        return 0
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let controller = artistsController {
            let sectionInfo = artistsController.sections![section] as NSFetchedResultsSectionInfo
            return sectionInfo.numberOfObjects
        }
        return 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell",
            forIndexPath: indexPath) as ArtistCell
        let song = artistsController.objectAtIndexPath(indexPath) as NSDictionary
        let artist = song.objectForKey("artist") as NSString
        cell.artistLabel.text = artist
        if let artistInfo = artistsInfo.objectForKey(artist) as? NSDictionary {
            
            let albumCount = artistInfo.objectForKey("albumCount") as NSInteger
            cell.infoLabel.text = NSString(format: "%d %@", albumCount, albumCount == 1 ? "album" : "albums")
            
            if let image = artistInfo.objectForKey("artwork") as? UIImage {
                cell.artistImageView.image = image
            } else {
                cell.artistImageView.image = UIImage(named: "noArtwork")
            }
        } else {
            cell.artistImageView.image = UIImage(named: "noArtwork")
            cell.infoLabel.text = NSString(format: "0 albums")
        }
        
        return cell
    }
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 30
    }
    
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        let sectionInfo = artistsController.sections![section] as NSFetchedResultsSectionInfo
        
        let header = tableView.dequeueReusableHeaderFooterViewWithIdentifier("Header") as ArtistsHeader
        
        header.infoLabel.text = sectionInfo.name
        
        return header
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        let song = artistsController.objectAtIndexPath(indexPath) as NSDictionary
        let artist = song.objectForKey("artist") as NSString
        
        let artistAlbumsViewController = ArtistAlbumsViewController(artist: artist)
        navigationController?.pushViewController(artistAlbumsViewController, animated: true)
    }
    
    func sectionIndexTitlesForTableView(tableView: UITableView) -> [AnyObject]! {
        if let controller = artistsController {
            return artistsController.sectionIndexTitles
        }
        return []
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
