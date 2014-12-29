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
    
    var createPlaylistCell: CreatePlaylistCell!
    var artist: NSString!
    var items: [MPMediaItem]!
    var hud: MBProgressHUD!
    
    var existingPlaylist: Playlist?
    
    override init() {
        super.init(nibName: "CreatePlaylistOverlay", bundle: nil)
    }
    
    init(artist: NSString!) {
        self.artist = artist
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
        createPlaylistCell.nameTextField.becomeFirstResponder()
        
        self.overlayScreenName = "New Playlist"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.registerNib(UINib(nibName: "CreatePlaylistCell", bundle: nil), forCellReuseIdentifier: "Cell")
        
        tableView.reloadData()
        
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
        createPlaylistCell = nib.instantiateWithOwner(self, options: nil)[0] as CreatePlaylistCell
        createPlaylistCell.delegate = self
        
        if let artist = self.artist {
            createPlaylistCell.smartSwitch.enabled = true
        } else {
            createPlaylistCell.smartSwitch.enabled = false
        }
    }
    
    private func requestSimiliarArtists() {
        var similiarArtistLastFmRequest = LastFmSimiliarArtistsRequest(artist: self.artist)
        similiarArtistLastFmRequest.delegate = self
        similiarArtistLastFmRequest.sendURLRequest()
    }
    
    func lastFmSimiliarArtistsRequestDidComplete(request: LastFmSimiliarArtistsRequest, didCompleteWithLastFmArtists artists: [AnyObject]?) {
        let index = createPlaylistCell.amountSegmentedControl.selectedSegmentIndex
        let amount = createPlaylistCell.amountSegmentedControl.titleForSegmentAtIndex(index)!.toInt()!
        let name = createPlaylistCell.nameTextField.text
        let playlistType = PlaylistType.Smart
        MediaSession.sharedSession.dataManager.datastore.createPlaylistWithSimiliarArtists(artists,
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
            createPlaylistCell.selectionStyle = .None
            return createPlaylistCell
        } else {
            var cell = UITableViewCell(style: .Default, reuseIdentifier: "Cell")
            if let playlist = existingPlaylist {
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
                    message: "You haven't selected to add to an existing playlist.",
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

    func createPlaylistCell(cell: CreatePlaylistCell, didStartEditing textField: UITextField!) {
        
    }
    
    func createPlaylistCell(cell: CreatePlaylistCell, shouldReturn textField: UITextField!) {
        createPlaylist()
    }

    
    func createPlaylist() {
        if createPlaylistCell.smartSwitch.on {
            hud = MBProgressHUD.showHUDAddedTo(self.view, animated: true)
            hud.mode = MBProgressHUDModeIndeterminate
            hud.labelText = "Getting similiar artists"
            requestSimiliarArtists()
        } else {
            if let artist = self.artist {
                if let playlist = existingPlaylist {
                    if let items = self.items {
                        // Create playlist with items.
                        MediaSession.sharedSession.dataManager.datastore.addItemsToPlaylist(items, playlist: playlist, completion: { (addedSongs) -> () in
                            self.handleCreatePlaylistFinishWithAddedSongs(addedSongs)
                        })
                    } else {
                        // Create playlist with artist items.
                        MediaSession.sharedSession.dataManager.datastore.addArtistSongsToPlaylist(playlist, artist: artist, completion: { (addedSongs) -> () in
                            self.handleCreatePlaylistFinishWithAddedSongs(addedSongs)
                        })
                    }
                } else {
                    if countElements(createPlaylistCell.nameTextField.text) > 0 {
                        if let items = self.items {
                            MediaSession.sharedSession.dataManager.datastore.createPlaylistWithItems(createPlaylistCell.nameTextField.text, items: items, completion: { (addedSongs) -> () in
                                self.handleCreatePlaylistFinishWithAddedSongs(addedSongs)
                            })
                        } else {
                            MediaSession.sharedSession.dataManager.datastore.createPlaylistWithArtist(self.artist,
                                name: createPlaylistCell.nameTextField.text,
                                playlistType: .None) { (addedSongs) -> () in
                                    self.handleCreatePlaylistFinishWithAddedSongs(addedSongs)
                            }
                        }
                    } else {
                        showEmptyPlaylistNameAlert()
                    }
                }
            } else {
                if countElements(createPlaylistCell.nameTextField.text) > 0 {
                    MediaSession.sharedSession.dataManager.datastore.createEmptyPlaylistWithName(createPlaylistCell.nameTextField.text,
                        playlistType: .None) { () -> () in
                            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                self.dismiss()
                            })
                    }
                } else {
                    showEmptyPlaylistNameAlert()
                }
                
            }
        }
    }
    
    func showEmptyPlaylistNameAlert() {
        UIAlertView(title: "Error!", message: "You must set a playlist name!", delegate: self, cancelButtonTitle: "Ok").show()
    }
    
    private func handleCreatePlaylistFinishWithAddedSongs(addedSongs: [AnyObject]?) {
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            if let songsAdded = addedSongs {
                LocalyticsSession.shared().tagEvent("Successful smart playlist created.")
                self.dismiss()
            } else {
                LocalyticsSession.shared().tagEvent("Create smart playlist failed.")
                let errorMessage = "Unable to find any songs based on \(self.artist)"
                UIAlertView(title: "Error!", message: errorMessage, delegate: self, cancelButtonTitle: "Ok").show()
                self.hud.hide(true)
            }
        })
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        createPlaylistCell.nameTextField.resignFirstResponder()
    }
    
    func playlistsViewController(controller: PlaylistsViewController, didSelectPlaylist playlist: Playlist) {
        self.existingPlaylist = playlist
        self.tableView.reloadData()
        
        createPlaylistCell.smartSwitch.on = false
        createPlaylistCell.smartSwitchDidChange(createPlaylistCell.smartSwitch)
        createPlaylistCell.smartSwitch.enabled = false
        createPlaylistCell.nameTextField.text = ""
        createPlaylistCell.nameTextField.enabled = false
    }
}