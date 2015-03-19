//
//  CreatePlaylistOverlay.swift
//  Muz
//
//  Created by Nick Lanasa on 12/19/14.
//  Copyright (c) 2014 Nytek Productions. All rights reserved.
//

import Foundation
import UIKit
import MediaPlayer

enum CreatePlaylistSourceType: NSInteger {
    case Artist
    case Song
}

class CreatePlaylistOverlay: OverlayController,
UITableViewDelegate,
UITableViewDataSource,
UIScrollViewDelegate,
CreatePlaylistCellDelegate,
LastFmSimiliarArtistsRequestDelegate,
PlaylistsViewControllerDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    private var createPlaylistCell: CreatePlaylistCell!
    var artist: NSString!
    var items: [MPMediaItem]!
    
    var song: Song!
    var songs: [AnyObject]!
    
    private var hud: MBProgressHUD!
    
    var existingPlaylist: Playlist?
    
    override init() {
        super.init(nibName: "CreatePlaylistOverlay", bundle: nil)
    }
    
    init(song: Song) {
        self.song = song
        self.artist = song.artist
        super.init(nibName: "CreatePlaylistOverlay", bundle: nil)
    }
    
    init(songs: [AnyObject]) {
        self.songs = songs
        if songs.count > 0 {
            let song: Song = songs[0] as Song
            self.song = song
            self.artist = song.artist
        }
        super.init(nibName: "CreatePlaylistOverlay", bundle: nil)
    }
    
    init(artist: NSString!) {
        self.artist = artist
        
        super.init(nibName: "CreatePlaylistOverlay", bundle: nil)
    }
    
    init(artist: Artist!) {
        self.artist = artist.name
        super.init(nibName: "CreatePlaylistOverlay", bundle: nil)
    }
    
    init(items: [MPMediaItem]!) {
        self.items = items
        if items.count > 0 {
            let firstItem: MPMediaItem = items[0] as MPMediaItem
            self.artist = firstItem.artist
        }
        super.init(nibName: "CreatePlaylistOverlay", bundle: nil)
    }
    
    override func viewWillAppear(animated: Bool) {
        self.createPlaylistCell.nameTextField.becomeFirstResponder()
        
        self.overlayScreenName = "New Playlist"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.registerNib(UINib(nibName: "CreatePlaylistCell", bundle: nil), forCellReuseIdentifier: "Cell")
        
        self.tableView.reloadData()
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel",
            style: .Plain,
            target: self,
            action: "dismiss")
    
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Done",
            style: .Plain,
            target: self,
            action: "createPlaylist")
        
        var nib = UINib(nibName: "CreatePlaylistCell",
            bundle: nil)
        self.createPlaylistCell = nib.instantiateWithOwner(self, options: nil)[0] as CreatePlaylistCell
        self.createPlaylistCell.delegate = self
        
        if let artist = self.artist {
            self.createPlaylistCell.smartSwitch.enabled = true
        } else {
            self.createPlaylistCell.smartSwitch.enabled = false
        }
    }
    
    private func requestSimiliarArtists() {
        var similiarArtistLastFmRequest = LastFmSimiliarArtistsRequest(artist: self.artist)
        similiarArtistLastFmRequest.delegate = self
        similiarArtistLastFmRequest.sendURLRequest()
    }
    
    func lastFmSimiliarArtistsRequestDidComplete(request: LastFmSimiliarArtistsRequest,
        didCompleteWithLastFmArtists artists: [AnyObject]?) {
        let index = self.createPlaylistCell.amountSegmentedControl.selectedSegmentIndex
        let amount = self.createPlaylistCell.amountSegmentedControl.titleForSegmentAtIndex(index)!.toInt()!
        let name = self.createPlaylistCell.nameTextField.text
        let playlistType = PlaylistType.Smart
        MediaSession.sharedSession.dataManager.datastore.createPlaylistWithSimiliarArtists(self.artist,
            artists: artists,
            fetchLimit: amount,
            name: name,
            playlistType: playlistType) { (addedSongs) -> () in
            self.handleCreatePlaylistFinishWithAddedSongs(addedSongs)
        }
    }
    
    func dismiss() {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if indexPath.section == 1 {
            self.createPlaylistCell.selectionStyle = .None
            return self.createPlaylistCell
        } else {
            var cell = UITableViewCell(style: .Default, reuseIdentifier: "Cell")
            if let playlist = self.existingPlaylist {
                cell.textLabel?.text = playlist.name
            } else {
                cell.textLabel?.text = "Add to existing playlist"
            }
            cell.textLabel?.font = MuzSettingFont
            cell.textLabel?.textColor = UIColor.whiteColor()
            cell.accessoryType = .DisclosureIndicator
            return cell
        }
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.section == 1 {
            return CreatePlaylistCellHeight
        } else {
            return 45.0
        }
    }
    
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == 1 {
            
        } else {
            if self.artist == nil {
                UIAlertView(title: "Error!",
                    message: "You haven't selected anything to add to an existing playlist.",
                    delegate: self,
                    cancelButtonTitle: "Ok").show()
            } else {
                var playlistsViewController = PlaylistsViewController(existingPlaylist: true)
                playlistsViewController.delegate = self
                self.navigationController?.pushViewController(playlistsViewController, animated: true)
            }
        }
        
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }

    // MARK: CreatePlaylistCellDelegate
    func createPlaylistCell(cell: CreatePlaylistCell, didStartEditing textField: UITextField!) {
        
    }
    
    func createPlaylistCell(cell: CreatePlaylistCell, shouldReturn textField: UITextField!) {
        self.createPlaylist()
    }

    func createPlaylist() {
        if self.createPlaylistCell.smartSwitch.on {
            self.hud = MBProgressHUD.showHUDAddedTo(self.view, animated: true)
            self.hud.mode = .Indeterminate
            self.hud.labelText = "Getting similiar artists"
            self.hud.labelFont = MuzTitleFont
            requestSimiliarArtists()
        } else {
            if let artist = self.artist {
                if let playlist = self.existingPlaylist {
                    if let songs = self.songs {
                        // Create playlist with items.
                        MediaSession.sharedSession.dataManager.datastore.addSongsToPlaylist(songs,
                            playlist: playlist,
                            completion: { (addedSongs) -> () in
                            self.handleCreatePlaylistFinishWithAddedSongs(addedSongs)
                        })
                    } else {
                        // Create playlist with artist items.
                        MediaSession.sharedSession.dataManager.datastore.addArtistSongsToPlaylist(playlist,
                            artist: artist,
                            completion: { (addedSongs) -> () in
                            self.handleCreatePlaylistFinishWithAddedSongs(addedSongs)
                        })
                    }
                } else {
                    if countElements(self.createPlaylistCell.nameTextField.text) > 0 {
                        if let songs = self.songs {
                            MediaSession.sharedSession.dataManager.datastore.createPlaylistWithSongs(self.createPlaylistCell.nameTextField.text,
                                songs: songs,
                                completion: { (addedSongs) -> () in
                                LocalyticsSession.shared().tagEvent("Playlist created.")
                                self.dismiss()
                            })
                        } else {
                            MediaSession.sharedSession.dataManager.datastore.createPlaylistWithArtist(self.artist,
                                name: self.createPlaylistCell.nameTextField.text,
                                playlistType: .None) { (addedSongs) -> () in
                                    LocalyticsSession.shared().tagEvent("Playlist created.")
                                    self.dismiss()
                            }
                        }
                    } else {
                        showEmptyPlaylistNameAlert()
                    }
                }
            } else {
                if countElements(self.createPlaylistCell.nameTextField.text) > 0 {
                    MediaSession.sharedSession.dataManager.datastore.createEmptyPlaylistWithName(self.createPlaylistCell.nameTextField.text,
                        playlistType: .None) { () -> () in
                            LocalyticsSession.shared().tagEvent("Playlist created.")
                            self.dismiss()
                    }
                } else {
                    showEmptyPlaylistNameAlert()
                }
                
            }
        }
    }
    
    private func showEmptyPlaylistNameAlert() {
        UIAlertView(title: "Error!",
            message: "You must set a playlist name!",
            delegate: self,
            cancelButtonTitle: "Ok").show()
    }
    
    private func handleCreatePlaylistFinishWithAddedSongs(addedSongs: [AnyObject]?) {
        if let songsAdded = addedSongs {
            LocalyticsSession.shared().tagEvent("Successful smart playlist created.")
            self.dismiss()
        } else {
            LocalyticsSession.shared().tagEvent("Create smart playlist failed.")
            let errorMessage = "Unable to find any songs based on \(self.artist)"
            UIAlertView(title: "Error!",
                message: errorMessage,
                delegate: self,
                cancelButtonTitle: "Ok").show()
            self.hud.hide(true)
        }
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        self.createPlaylistCell.nameTextField.resignFirstResponder()
    }
    
    func playlistsViewController(controller: PlaylistsViewController, didSelectPlaylist playlist: Playlist) {
        self.existingPlaylist = playlist
        self.tableView.reloadData()
        
        self.createPlaylistCell.smartSwitch.on = false
        self.createPlaylistCell.smartSwitchDidChange(self.createPlaylistCell.smartSwitch)
        self.createPlaylistCell.smartSwitch.enabled = false
        self.createPlaylistCell.nameTextField.text = ""
        self.createPlaylistCell.nameTextField.enabled = false
    }
}