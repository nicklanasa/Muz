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
NSFetchedResultsControllerDelegate,
UISearchBarDelegate,
UISearchDisplayDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    // The NSFetchedResultsController used to pull tasks for the selected date.
    var songs: NSArray?
    var songsQuery: MPMediaQuery?
    var songsSections = NSMutableArray()
    
    override init() {
        super.init(nibName: "SongsViewController", bundle: nil)
        
        self.tabBarItem = UITabBarItem(title: nil,
            image: UIImage(named: "songs"),
            selectedImage: UIImage(named: "songs"))
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidAppear(animated: Bool) {
        self.screenName = "Songs"
        super.viewWillAppear(animated)
        fetchSongsWithPredicate(nil)
    }
    
    override func viewWillDisappear(animated: Bool) {
        searchBar.resignFirstResponder()
        self.tableView.setEditing(false, animated: false)
        self.searchDisplayController?.setActive(false, animated: false)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.registerNib(UINib(nibName: "SongCell", bundle: nil), forCellReuseIdentifier: "Cell")
        tableView.registerNib(UINib(nibName: "SongsHeader", bundle: nil), forHeaderFooterViewReuseIdentifier: "Header")
        
        searchDisplayController?.searchResultsTableView.registerNib(UINib(nibName: "SongCell", bundle: nil), forCellReuseIdentifier: "Cell")
        searchDisplayController?.searchResultsTableView.registerNib(UINib(nibName: "SongsHeader", bundle: nil), forHeaderFooterViewReuseIdentifier: "Header")
        
        tableView.backgroundView = UIView()
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "search"),
            style: .Plain,
            target: self,
            action: "showSearch")
    }
    
    func showSearch() {
        self.searchDisplayController?.setActive(true, animated: true)
    }
    
    func fetchSongsWithPredicate(predicate: MPMediaPropertyPredicate?) {
        
        songsQuery = MediaSession.sharedSession.songsQueryWithPredicate(predicate)
        
        songs = songsQuery?.items
        songsSections = NSMutableArray()
        
        if let query = songsQuery {
            if let itemSections = query.itemSections {
                for section in itemSections {
                    if let songSection = section as? MPMediaQuerySection {
                        songsSections.addObject(songSection.title)
                    }
                }
            }
        }
        
        self.tableView.reloadData()
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return songsQuery?.itemSections?.count ?? 0
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
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 55
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell",
            forIndexPath: indexPath) as SongCell

        let section = self.songsQuery?.itemSections[indexPath.section] as MPMediaQuerySection
        
        if let item = songs?[indexPath.row + section.range.location] as? MPMediaItem {
            cell.updateWithItem(item)
        }
    
        return cell
    }
    
    func sectionIndexTitlesForTableView(tableView: UITableView) -> [AnyObject]! {
        return songsSections
    }
    
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        // Get song.
        let section = self.songsQuery?.itemSections[indexPath.section] as MPMediaQuerySection
        
        self.searchDisplayController?.setActive(false, animated: false)
        
        if let song = self.songs?[indexPath.row + section.range.location] as? MPMediaItem {
            presentNowPlayViewControllerWithItem(song, collection: MPMediaItemCollection(items: self.songs))
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
            let section = self.songsQuery?.itemSections[indexPath.section] as MPMediaQuerySection
            
            if let song = self.songs?[indexPath.row + section.range.location] as? MPMediaItem {
                let createPlaylistOverlay = CreatePlaylistOverlay(items: [song])
                self.presentModalOverlayController(createPlaylistOverlay, blurredController: self)
            }
        })
        
        return [addToPlaylistAction]
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        if scrollView.contentOffset.y < 0 {
            searchBar.becomeFirstResponder()
        }
    }
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        if countElements(searchText) == 0 {
            fetchSongsWithPredicate(nil)
        } else {
            let songPredicate = MPMediaPropertyPredicate(value: searchText, forProperty: MPMediaItemPropertyTitle, comparisonType: .Contains)
            songsQuery?.addFilterPredicate(songPredicate)
            fetchSongsWithPredicate(songPredicate)
        }
    }
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        fetchSongsWithPredicate(nil)
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
