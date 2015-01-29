//
//  PlaylistSongsViewController.swift
//  Muz
//
//  Created by Nick Lanasa on 12/15/14.
//  Copyright (c) 2014 Nytek Productions. All rights reserved.
//

import Foundation
import UIKit
import MediaPlayer
import CoreData

class PlaylistSongsViewController: RootViewController,
    UITableViewDelegate,
UITableViewDataSource,
NSFetchedResultsControllerDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    var playlist: Playlist!
    var isReadOnly = false
    
    private var sortedPlaylistSongs: [AnyObject]!
    private var readOnlyPlaylistSongsQuery: MPMediaQuery?
    
    init(playlist: Playlist) {
        self.playlist = playlist
        super.init(nibName: "PlaylistSongsViewController", bundle: nil)
    }
    
    override init() {
        super.init(nibName: "PlaylistSongsViewController", bundle: nil)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewWillAppear(animated: Bool) {
        self.fetchPlaylistSongs()
        super.viewWillAppear(animated)
        
        self.screenName = "Playlist songs"
        
        self.navigationItem.title = self.playlist.name
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.registerNib(UINib(nibName: "SongCell", bundle: nil), forCellReuseIdentifier: "Cell")
        
        var songs = NSSet(set: self.playlist.playlistSongs)
        let sort = NSSortDescriptor(key: "order", ascending: true)
        self.sortedPlaylistSongs = songs.sortedArrayUsingDescriptors([sort])
        
        if self.playlist.persistentID.isEmpty {
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Edit",
                style: .Plain,
                target: self,
                action: "editPlaylist")
        }
        
        self.tableView.allowsMultipleSelectionDuringEditing = true

    }

    func editPlaylist() {
        self.tableView.setEditing(true, animated: true)
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Done",
            style: .Plain,
            target: self,
            action: "finishEditing")
    }
    
    func finishEditing() {
        
        let selectedRows = self.tableView.indexPathsForSelectedRows()
        if selectedRows?.count > 0 {
            // Delete songs
            var playlistSongs = NSMutableSet(set: self.playlist.playlistSongs)
            
            for indexPath in selectedRows as [NSIndexPath] {
                let playlistSong = self.sortedPlaylistSongs[indexPath.row] as PlaylistSong
                playlistSongs.removeObject(playlistSong)
                self.sortedPlaylistSongs.removeAtIndex(indexPath.row)
            }
            
            self.playlist.playlistSongs = playlistSongs
            
            MediaSession.sharedSession.dataManager.datastore.saveDatastoreWithCompletion({ (error) -> () in
                if error != nil {
                    println("Unabled to updated playlist.")
                } else {
                    println("Updated playlist!")
                }
            })
            
            self.tableView.deleteRowsAtIndexPaths(selectedRows!, withRowAnimation: .Fade)
        }
        
        self.tableView.setEditing(false, animated: true)
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Edit",
            style: .Plain,
            target: self,
            action: "editPlaylist")
    }
    
    private func addPlaylist() {
        
    }
    
    private func fetchPlaylistSongs() {
        if !self.playlist.persistentID.isEmpty {
            self.isReadOnly = true
            
            self.readOnlyPlaylistSongsQuery = MediaSession.sharedSession.playlistSongsForPlaylist(self.playlist)
            
            self.tableView.reloadData()
        }
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if self.isReadOnly {
            return self.readOnlyPlaylistSongsQuery?.items.count ?? 0
        }
        
        return self.sortedPlaylistSongs.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell",
            forIndexPath: indexPath) as SongCell
                
        if self.isReadOnly {
            let readOnlyPlaylist = self.readOnlyPlaylistSongsQuery?.collections?[indexPath.section] as MPMediaPlaylist
            if let item = readOnlyPlaylist.items[indexPath.row] as? MPMediaItem {
                cell.updateWithItem(item)
            }
        } else {
            let playlistSong = self.sortedPlaylistSongs[indexPath.row] as PlaylistSong
            let song = playlistSong.song
            cell.updateWithSong(song)
        }
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if tableView.editing == true {
            return
        } else {
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
            
            if self.isReadOnly {
                let readOnlyPlaylist = self.readOnlyPlaylistSongsQuery?.collections?[indexPath.section] as MPMediaPlaylist
                if let song = readOnlyPlaylist.items[indexPath.row] as? MPMediaItem {
                    self.presentNowPlayViewControllerWithItem(song, collection: MPMediaItemCollection(items: readOnlyPlaylist.items))
                }
            } else {
                // Create collection of playlist songs.
                let playlistSong = self.sortedPlaylistSongs[indexPath.row] as PlaylistSong
                let song = playlistSong.song
                let collection = MediaSession.sharedSession.collectionWithPlaylistSongs(sortedPlaylistSongs)
                if let item = MediaSession.sharedSession.itemForSong(song) {
                    self.presentNowPlayViewControllerWithItem(item, collection: collection)
                }
            }
        }
    }
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        
    }
    
    func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    func tableView(tableView: UITableView, moveRowAtIndexPath sourceIndexPath: NSIndexPath, toIndexPath destinationIndexPath: NSIndexPath) {
        var playlistSongSource = self.sortedPlaylistSongs[sourceIndexPath.row] as PlaylistSong
        var playlistSongTo = self.sortedPlaylistSongs[destinationIndexPath.row] as PlaylistSong
        playlistSongSource.order = destinationIndexPath.row + 1
        playlistSongTo.order = sourceIndexPath.row + 1
        
        MediaSession.sharedSession.dataManager.datastore.mainQueueContext.save(NSErrorPointer())
    }
    
    func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [AnyObject]? {
        let deleteAction = UITableViewRowAction(style: UITableViewRowActionStyle.Default,
            title: "Delete",
            handler: { (action, indexPath) -> Void in
            
        })

        return [deleteAction]
    }
}