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

class PlaylistsViewController: RootViewController,
    UITableViewDelegate,
UITableViewDataSource,
NSFetchedResultsControllerDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    // The NSFetchedResultsController used to pull tasks for the selected date.
    var playlistsController: NSFetchedResultsController?
    
    override init() {
        super.init(nibName: "PlaylistsViewController", bundle: nil)
        
        self.tabBarItem = UITabBarItem(title: nil,
            image: UIImage(named: "playlists"),
            selectedImage: UIImage(named: "playlists"))
        self.tabBarItem.imageInsets = UIEdgeInsetsMake(6, 0, -6, 0)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewWillAppear(animated: Bool) {
        fetchPlaylists()
        super.viewWillAppear(animated)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.registerNib(UINib(nibName: "PlaylistCell", bundle: nil), forCellReuseIdentifier: "Cell")
        tableView.registerNib(UINib(nibName: "SongsHeader", bundle: nil), forHeaderFooterViewReuseIdentifier: "Header")
        self.navigationItem.title = "Playlists"
    
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "add"),
            style: .Plain,
            target: self,
            action: "addPlaylist");
    }
    
    func addPlaylist() {
        
    }
    
    func fetchPlaylists() {
        playlistsController = MediaSession.sharedSession.dataManager.datastore.playlistsControllerWithSectionName(nil)
        playlistsController?.delegate = self
        var error: NSError?
        if playlistsController!.performFetch(&error) {
            self.tableView.reloadData()
        }
        
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return playlistsController?.sections?.count ?? 0
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let numberOfRowsInSection = playlistsController?.sections?[section].numberOfObjects {
            return numberOfRowsInSection
        } else {
            return 0
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell",
            forIndexPath: indexPath) as PlaylistCell
        let playlist = playlistsController?.objectAtIndexPath(indexPath) as Playlist
        cell.updateWithPlaylist(playlist)
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        let playlist = playlistsController?.objectAtIndexPath(indexPath) as Playlist
        let playlistSongsViewController = PlaylistSongsViewController(playlist: playlist)
        self.navigationController?.pushViewController(playlistSongsViewController, animated: true)
    }
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        let playlist = playlistsController?.objectAtIndexPath(indexPath) as Playlist
        return countElements(playlist.persistentID) == 0
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        
    }
    
    func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [AnyObject]? {
        let deleteAction = UITableViewRowAction(style: UITableViewRowActionStyle.Default, title: "Delete", handler: { (action, indexPath) -> Void in
            let playlist = self.playlistsController?.objectAtIndexPath(indexPath) as Playlist
            MediaSession.sharedSession.dataManager.datastore.deletePlaylistWithPlaylist(playlist, completion: { (error) -> () in
                if error == nil {
                    
                } else {
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        UIAlertView(title: "Error!",
                            message: "Unable to delete playlist!",
                            delegate: self,
                            cancelButtonTitle: "Ok").show()
                    })
                }
            })
        })

        return [deleteAction]
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        switch type {
        case .Delete:
            if let path = indexPath {
                self.tableView.deleteRowsAtIndexPaths([path], withRowAnimation: .Fade)
            }
        default: break
        }
    }
}