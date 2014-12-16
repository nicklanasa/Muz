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
UITableViewDataSource {
    
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.registerNib(UINib(nibName: "ArtistCell", bundle: nil), forCellReuseIdentifier: "Cell")
        
        fetchPlaylists()
        
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
            forIndexPath: indexPath) as ArtistCell
       let playlist = playlistsController?.objectAtIndexPath(indexPath) as Playlist
        cell.artistLabel.text = playlist.name
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
//        let song = sortedResults[indexPath.row] as MPMediaItem
//        presentNowPlayViewControllerWithItem(song)
//        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        searchBar.resignFirstResponder()
    }
}