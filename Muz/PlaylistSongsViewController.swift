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
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


class PlaylistSongsViewController: RootViewController,
    UITableViewDelegate,
UITableViewDataSource,
NSFetchedResultsControllerDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    var playlist: Playlist!
    var isReadOnly = false
    
    fileprivate var sortedPlaylistSongs: [AnyObject]!
    fileprivate var readOnlyPlaylistSongsQuery: MPMediaQuery?
    
    init(playlist: Playlist) {
        self.playlist = playlist
        super.init(nibName: "PlaylistSongsViewController", bundle: nil)
    }
    
    init() {
        super.init(nibName: "PlaylistSongsViewController", bundle: nil)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.fetchPlaylistSongs()
        super.viewWillAppear(animated)
        
        self.screenName = "Playlist songs"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.register(UINib(nibName: "SongCell", bundle: nil), forCellReuseIdentifier: "Cell")
        
        if let _ = self.playlist {
            self.navigationItem.title = self.playlist?.name
            let songs = NSSet(set: self.playlist.playlistSongs)
            let sort = NSSortDescriptor(key: "order", ascending: true)
            self.sortedPlaylistSongs = songs.sortedArray(using: [sort]) as [AnyObject]
            
            if let persistentID = self.playlist.persistentID {
                if persistentID.isEmpty {
                    self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Edit",
                        style: .plain,
                        target: self,
                        action: #selector(PlaylistSongsViewController.editPlaylist))
                }
            }
        }
        
        self.tableView.allowsMultipleSelectionDuringEditing = true

    }

    func editPlaylist() {
        self.tableView.setEditing(true, animated: true)
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Done",
            style: .plain,
            target: self,
            action: #selector(PlaylistSongsViewController.finishEditing))
    }
    
    func finishEditing() {
        let selectedRows = self.tableView.indexPathsForSelectedRows
        if selectedRows?.count > 0 {
            // Delete songs
            let playlistSongs = NSMutableSet(set: self.playlist.playlistSongs)
            
            for indexPath in selectedRows! {
                let playlistSong = self.sortedPlaylistSongs[indexPath.row] as! PlaylistSong
                playlistSongs.remove(playlistSong)
                self.sortedPlaylistSongs.remove(at: indexPath.row)
            }
            
            self.playlist.playlistSongs = playlistSongs
            
            MediaSession.sharedSession.dataManager.datastore.saveDatastoreWithCompletion({ (error) -> () in
                if error != nil {
                    print("Unabled to updated playlist.")
                } else {
                    print("Updated playlist!")
                }
            })
            
            self.tableView.deleteRows(at: selectedRows!, with: .fade)
        }
        
        self.tableView.setEditing(false, animated: true)
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Edit",
            style: .plain,
            target: self,
            action: #selector(PlaylistSongsViewController.editPlaylist))
    }
    
    fileprivate func addPlaylist() {
        
    }
    
    fileprivate func fetchPlaylistSongs() {
        if let persistentID = self.playlist.persistentID {
            if !persistentID.isEmpty {
                self.isReadOnly = true
                
                self.readOnlyPlaylistSongsQuery = MediaSession.sharedSession.playlistSongsForPlaylist(self.playlist)
                
                self.tableView.reloadData()
            }
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if self.isReadOnly {
            return self.readOnlyPlaylistSongsQuery?.items?.count ?? 0
        }
        
        return self.sortedPlaylistSongs.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell",
            for: indexPath) as! SongCell
                
        if self.isReadOnly {
            let readOnlyPlaylist = self.readOnlyPlaylistSongsQuery?.collections?[indexPath.section] as! MPMediaPlaylist
            let item = readOnlyPlaylist.items[indexPath.row]
            cell.updateWithItem(item)
        } else {
            let playlistSong = self.sortedPlaylistSongs[indexPath.row] as! PlaylistSong
            let song = playlistSong.song
            cell.updateWithSong(song)
        }
        
        cell.accessoryType = .disclosureIndicator
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView.isEditing == true {
            if self.tableView.indexPathsForSelectedRows?.count > 0 {
                self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Delete",
                    style: .plain,
                    target: self,
                    action: #selector(PlaylistSongsViewController.finishEditing))
            } else {
                self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Done",
                    style: .plain,
                    target: self,
                    action: #selector(PlaylistSongsViewController.editPlaylist))
            }
            
            return
        } else {
            tableView.deselectRow(at: indexPath, animated: true)
            
            if self.isReadOnly {
                let readOnlyPlaylist = self.readOnlyPlaylistSongsQuery?.collections?[indexPath.section] as! MPMediaPlaylist
                let item = readOnlyPlaylist.items[indexPath.row]
                if let title = item.title, let artist = item.artist {
                    DataManager.manager.datastore.songForSongName(title, artist: artist, completion: { (song) -> () in
                        if let songToPlay = song {
                            self.presentNowPlayViewController(songToPlay, collection: MPMediaItemCollection(items: readOnlyPlaylist.items))
                        }
                    })
                } else {
                    UIAlertView(title: "Error!",
                        message: "Unable to find song!",
                        delegate: self,
                        cancelButtonTitle: "Ok").show()
                }
            } else {
                // Create collection of playlist songs.
                let playlistSong = self.sortedPlaylistSongs[indexPath.row] as! PlaylistSong
                let song = playlistSong.song
                if let collection = MediaSession.sharedSession.collectionWithPlaylistSongs(sortedPlaylistSongs) {
                    self.presentNowPlayViewController(song, collection: collection)
                } else {
                    UIAlertView(title: "Error!",
                        message: "Unable to get collection!",
                        delegate: self,
                        cancelButtonTitle: "Ok").show()
                }
            }
        }
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        
    }
    
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let playlistSongSource = self.sortedPlaylistSongs[sourceIndexPath.row] as! PlaylistSong
        let playlistSongTo = self.sortedPlaylistSongs[destinationIndexPath.row] as! PlaylistSong
        playlistSongSource.order = NSNumber(destinationIndexPath.row + 1)
        playlistSongTo.order = NSNumber(sourceIndexPath.row + 1)
        
        do {
            try MediaSession.sharedSession.dataManager.datastore.mainQueueContext.save()
        } catch let error as NSError {
            nil.pointee = error
        }
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let deleteAction = UITableViewRowAction(style: UITableViewRowActionStyle.default,
            title: "Delete",
            handler: { (action, indexPath) -> Void in
            
        })

        return [deleteAction]
    }
}
