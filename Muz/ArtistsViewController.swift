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
NSFetchedResultsControllerDelegate,
UISearchBarDelegate,
UISearchDisplayDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    var artists: NSArray?
    var filteredArtists: NSArray?
    var filteredArtistsSections = NSArray()
    var artistsQuery: MPMediaQuery?
    var artistsSections = NSArray()
    
    override init() {
        super.init(nibName: "ArtistsViewController", bundle: nil)
        
        self.tabBarItem = UITabBarItem(title: nil,
            image: UIImage(named: "artists"),
            selectedImage: UIImage(named: "artists"))
        self.tabBarItem.imageInsets = UIEdgeInsetsMake(6, 0, -6, 0)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.registerNib(UINib(nibName: "ArtistCell", bundle: nil), forCellReuseIdentifier: "Cell")
        tableView.registerNib(UINib(nibName: "ArtistsHeader", bundle: nil), forHeaderFooterViewReuseIdentifier: "Header")
        
        searchDisplayController?.searchResultsTableView.registerNib(UINib(nibName: "ArtistCell", bundle: nil), forCellReuseIdentifier: "Cell")
        searchDisplayController?.searchResultsTableView.registerNib(UINib(nibName: "ArtistsHeader", bundle: nil), forHeaderFooterViewReuseIdentifier: "Header")
    
        self.navigationItem.title = "Artists"
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "search"),
            style: .Plain,
            target: self,
            action: "showSearch")
        
        fetchArtists()
    }
    
    func showSearch() {
        self.searchDisplayController?.setActive(true, animated: true)
    }
    
    func fetchArtists() {
        artistsQuery = MediaSession.sharedSession.artistsQueryWithFilters(nil)
        artists = MediaSession.sharedSession.artistsCollectionWithQuery(artistsQuery!)
        artistsSections = MediaSession.sharedSession.artistsSectionIndexTitles(artistsQuery!)
     }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if let sections = artistsQuery?.collectionSections {
            return artistsQuery?.collectionSections.count ?? 0
        }
        return 0
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let section = artistsQuery?.collectionSections[section] as? MPMediaQuerySection
        return section?.range.length ?? 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell",
            forIndexPath: indexPath) as ArtistCell
        
        let section = self.artistsQuery?.collectionSections[indexPath.section] as MPMediaQuerySection
        
        if tableView == self.searchDisplayController?.searchResultsTableView {
            if let songs = filteredArtists?[indexPath.row + section.range.location] as? MPMediaItemCollection {
                if let song = songs.representativeItem {
                    cell.updateWithItem(song)
                    cell.infoLabel.text = NSString(format: "%d %@", songs.count, songs.count == 1 ? "song" : "songs")
                }
            }
        } else {
            if let songs = artists?[indexPath.row + section.range.location] as? MPMediaItemCollection {
                if let song = songs.representativeItem {
                    cell.updateWithItem(song)
                    cell.infoLabel.text = NSString(format: "%d %@", songs.count, songs.count == 1 ? "song" : "songs")
                }
            }
        }
    
        return cell
    }
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 30
    }
    
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if let section = artistsQuery?.collectionSections[section] as? MPMediaQuerySection {
            let header = tableView.dequeueReusableHeaderFooterViewWithIdentifier("Header") as ArtistsHeader
            header.infoLabel.text = section.title
            return header
        } else {
            return nil
        }
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    
        // Get song.
        let section = artistsQuery?.collectionSections[indexPath.section] as MPMediaQuerySection
        var artists: [AnyObject]?
        
        if tableView == self.searchDisplayController?.searchResultsTableView {
            artists = filteredArtists
        } else {
            artists = self.artists
        }
        
        if let albums = artists?[indexPath.row + section.range.location] as? MPMediaItemCollection {
            let artistAlbumsViewController = ArtistAlbumsViewController(artist: albums.representativeItem.artist)
            navigationController?.pushViewController(artistAlbumsViewController, animated: true)
        }
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    func sectionIndexTitlesForTableView(tableView: UITableView) -> [AnyObject]! {
        return tableView == self.searchDisplayController?.searchResultsTableView ? filteredArtistsSections : artistsSections
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return ArtistCellHeight
    }
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        
    }
    
    func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [AnyObject]? {
        let addToPlaylistAction = UITableViewRowAction(style: UITableViewRowActionStyle.Normal, title: "Add to Playlist", handler: { (action, indexPath) -> Void in
            
            let section = self.artistsQuery?.collectionSections[indexPath.section] as MPMediaQuerySection
            var artists: [AnyObject]?
            
            if tableView == self.searchDisplayController?.searchResultsTableView {
                artists = self.filteredArtists
            } else {
                artists = self.artists
            }
            
            if let albums = artists?[indexPath.row + section.range.location] as? MPMediaItemCollection {
                let createPlaylistOverlay = CreatePlaylistOverlay(artist: albums.representativeItem.artist)
                self.presentModalOverlayController(createPlaylistOverlay, blurredController: self)
            }
        })
        
        return [addToPlaylistAction]
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        //searchBar.resignFirstResponder()
    }
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        if countElements(searchText) == 0 {
            artistsQuery = MediaSession.sharedSession.artistsQueryWithFilters(nil)
            filteredArtists = MediaSession.sharedSession.artistsCollectionWithQuery(artistsQuery!)
        } else {
            let artistPredicate = MPMediaPropertyPredicate(value: searchText, forProperty: MPMediaItemPropertyArtist, comparisonType: .Contains)
            
            artistsQuery = MediaSession.sharedSession.artistsQueryWithFilters([artistPredicate])
            filteredArtists = MediaSession.sharedSession.artistsCollectionWithQuery(artistsQuery!)
            filteredArtistsSections = MediaSession.sharedSession.artistsSectionIndexTitles(artistsQuery!)
        }
        
        tableView.reloadData()
    }
    
    func searchDisplayControllerWillBeginSearch(controller: UISearchDisplayController) {
        searchBar.hidden = false
        searchBar.becomeFirstResponder()
    }
    
    func searchDisplayControllerWillEndSearch(controller: UISearchDisplayController) {
        searchBar.hidden = true
    }
    
    func searchDisplayController(controller: UISearchDisplayController, willShowSearchResultsTableView tableView: UITableView) {
        self.tabBarController?.tabBar.alpha = 0.0
        self.tableView.alpha = 0.0
    }
    
    func searchDisplayController(controller: UISearchDisplayController, willHideSearchResultsTableView tableView: UITableView) {
        self.tabBarController?.tabBar.alpha = 1.0
        self.tableView.alpha = 1.0
        self.tableView.reloadData()
    }
}
