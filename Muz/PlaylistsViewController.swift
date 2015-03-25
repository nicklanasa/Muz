//
//  PlaylistsViewController.swift
//  Muz
//
//  Created by Nick Lanasa on 12/15/14.
//  Copyright (c) 2014 Nytek Productions. All rights reserved.
//

import Foundation
import UIKit
import MediaPlayer
import CoreData

protocol PlaylistsViewControllerDelegate {
    func playlistsViewController(controller: PlaylistsViewController, didSelectPlaylist playlist: Playlist)
}

class PlaylistsViewController: RootViewController,
    UITableViewDelegate,
UITableViewDataSource,
NSFetchedResultsControllerDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    let isForExistingPlaylist = false
    
    // The NSFetchedResultsController used to pull tasks for the selected date.
    var playlistsController: NSFetchedResultsController?
    
    var delegate: PlaylistsViewControllerDelegate?
    
    override init() {
        super.init(nibName: "PlaylistsViewController", bundle: nil)
        
        self.tabBarItem = UITabBarItem(title: nil,
            image: UIImage(named: "playlists"),
            selectedImage: UIImage(named: "playlists"))
        
        self.tabBarItem.imageInsets = UIEdgeInsetsMake(6, 0, -6, 0)
    }
    
    init(existingPlaylist: Bool) {
        super.init(nibName: "PlaylistsViewController", bundle: nil)
        self.isForExistingPlaylist = existingPlaylist
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewWillDisappear(animated: Bool) {
        self.playlistsController = nil
    }
    
    override func viewWillAppear(animated: Bool) {
        self.fetchPlaylists()
        super.viewWillAppear(animated)
        
        self.screenName = "Playlists"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.registerNib(UINib(nibName: "PlaylistCell", bundle: nil), forCellReuseIdentifier: "Cell")
        self.tableView.registerNib(UINib(nibName: "SongsHeader", bundle: nil), forHeaderFooterViewReuseIdentifier: "Header")
    
        if !self.isForExistingPlaylist {
            var search = UIBarButtonItem(image: UIImage(named: "search"),
                style: .Plain,
                target: self,
                action: "showSearch")
            
            var addPlaylist = UIBarButtonItem(image: UIImage(named: "add"),
                style: .Plain,
                target: self,
                action: "addPlaylist");
            
            self.navigationItem.rightBarButtonItems = [addPlaylist, search]
        }
    }

    func showSearch() {
        self.presentSearchOverlayController(SearchOverlayController(), blurredController: self)
    }
    
    /**
    Show the create new playlist dialog.
    */
    func addPlaylist() {
        self.presentModalOverlayController(CreatePlaylistOverlay(), blurredController: self)
    }
    
    /**
    Fetch playlists
    */
    private func fetchPlaylists() {
        if !self.isForExistingPlaylist {
            self.playlistsController = DataManager.manager.datastore.playlistsControllerWithSectionName(nil,
                predicate: nil)
        } else {
            let predicate = NSPredicate(format: "persistentID == ''")
            self.playlistsController = DataManager.manager.datastore.playlistsControllerWithSectionName(nil,
                predicate: predicate)
        }
        
        self.playlistsController?.delegate = self
        
        var error: NSError?
        if self.playlistsController!.performFetch(&error) {
            
            self.tableView.reloadData()
            
            DataManager.manager.syncPlaylists({ (addedItems, error) -> () in
                
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

    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return self.playlistsController?.sections?.count ?? 0
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let numberOfRowsInSection = self.playlistsController?.sections?[section].numberOfObjects {
            return numberOfRowsInSection
        } else {
            return 0
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell",
            forIndexPath: indexPath) as PlaylistCell
        let playlist = self.playlistsController?.objectAtIndexPath(indexPath) as Playlist
        cell.updateWithPlaylist(playlist)
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if !self.isForExistingPlaylist {
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
            var playlist = self.playlistsController?.objectAtIndexPath(indexPath) as Playlist
            DataManager.manager.datastore.updatePlaylist(playlist: playlist, completion: { () -> () in
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    let playlistSongsViewController = PlaylistSongsViewController(playlist: playlist)
                    self.navigationController?.pushViewController(playlistSongsViewController, animated: true)
                })
            })
        } else {
            var playlist = self.playlistsController?.objectAtIndexPath(indexPath) as Playlist
            self.navigationController?.popViewControllerAnimated(true)
            self.dismissWithPlaylist(playlist)
        }
    }
    
    private func dismissWithPlaylist(playlist: Playlist) {
        self.delegate?.playlistsViewController(self, didSelectPlaylist: playlist)
    }
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        let playlist = self.playlistsController?.objectAtIndexPath(indexPath) as Playlist
        return countElements(playlist.persistentID!) == 0
    }
    
    func tableView(tableView: UITableView,
        commitEditingStyle editingStyle: UITableViewCellEditingStyle,
        forRowAtIndexPath indexPath: NSIndexPath) {
        
    }
    
    func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [AnyObject]? {
        let deleteAction = UITableViewRowAction(style: UITableViewRowActionStyle.Default, title: "Delete", handler: { (action, indexPath) -> Void in
            let playlist = self.playlistsController?.objectAtIndexPath(indexPath) as Playlist
            MediaSession.sharedSession.dataManager.datastore.deletePlaylistWithPlaylist(playlist, completion: { (error) -> () in
                if error == nil {
                    
                } else {
                    UIAlertView(title: "Error!",
                        message: "Unable to delete playlist!",
                        delegate: self,
                        cancelButtonTitle: "Ok").show()
                }
            })
        })

        return [deleteAction]
    }
}