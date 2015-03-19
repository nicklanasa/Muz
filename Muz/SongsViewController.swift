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
    
    lazy var songsController: NSFetchedResultsController = {
        let controller = DataManager.manager.datastore.songsControllerWithSortKey("title",
            limit: nil,
            ascending: true,
            sectionNameKeyPath: "title.stringByGroupingByFirstLetter")
        controller.delegate = self
        return controller
    }()
    
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
    
    override func viewDidAppear(animated: Bool) {
        self.screenName = "Songs"
        super.viewDidAppear(animated)
        
        fetchSongs()
    }
    
    func fetchSongs() {
        var error: NSError?
        if self.songsController.performFetch(&error) {
            self.tableView.reloadData()
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        self.tableView.setEditing(false, animated: false)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.registerNib(UINib(nibName: "SongCell", bundle: nil), forCellReuseIdentifier: "Cell")
        tableView.registerNib(UINib(nibName: "SongsHeader", bundle: nil), forHeaderFooterViewReuseIdentifier: "Header")
        
        tableView.backgroundView = UIView()
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "search"),
            style: .Plain,
            target: self,
            action: "showSearch")
    }

    func showSearch() {
        self.presentModalOverlayController(SearchOverlayController(), blurredController: self)
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let numberOfRowsInSection = self.songsController.sections?[section].numberOfObjects {
            return numberOfRowsInSection
        } else {
            return 0
        }
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return self.songsController.sections?.count ?? 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell",
            forIndexPath: indexPath) as SongCell
        
        let song = self.songsController.objectAtIndexPath(indexPath) as Song
        cell.updateWithSong(song)
        
        return cell
    }

    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if let sectionInfo = self.songsController.sections?[section] as? NSFetchedResultsSectionInfo {
            let header = tableView.dequeueReusableHeaderFooterViewWithIdentifier("Header") as SongsHeader
            header.infoLabel.text = sectionInfo.name
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

    func sectionIndexTitlesForTableView(tableView: UITableView) -> [AnyObject]! {
        return self.songsController.sectionIndexTitles
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        self.songsController.fetchRequest.predicate = nil
        self.searchDisplayController?.setActive(false, animated: false)
        
        // Get song.
        let song = self.songsController.objectAtIndexPath(indexPath) as Song
        
        DataManager.manager.fetchSongsCollection { (collection, error) -> () in
            self.presentNowPlayViewController(song, collection: collection)
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
                let song = self.songsController.objectAtIndexPath(indexPath) as Song
                let createPlaylistOverlay = CreatePlaylistOverlay(song: song)
                self.presentModalOverlayController(createPlaylistOverlay, blurredController: self)
        })
        
        return [addToPlaylistAction]
    }
}
