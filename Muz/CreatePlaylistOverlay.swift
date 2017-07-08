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


enum CreatePlaylistSourceType: NSInteger {
    case artist
    case song
}

class CreatePlaylistOverlay: OverlayController,
UITableViewDelegate,
UITableViewDataSource,
UIScrollViewDelegate,
CreatePlaylistCellDelegate,
LastFmSimiliarArtistsRequestDelegate,
PlaylistsViewControllerDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    fileprivate var createPlaylistCell: CreatePlaylistCell!
    
    var artist: String!
    var items: [MPMediaItem]!
    
    var song: Song!
    var songs: [AnyObject]!
    
    fileprivate var hud: MBProgressHUD!
    
    var existingPlaylist: Playlist?
    
    init() {
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
            let song: Song = songs[0] as! Song
            self.song = song
            self.artist = song.artist
        }
        super.init(nibName: "CreatePlaylistOverlay", bundle: nil)
    }
    
    init(artist: String!) {
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
 
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
   
    override func viewWillAppear(_ animated: Bool) {
        self.createPlaylistCell.nameTextField.becomeFirstResponder()
        
        self.overlayScreenName = "New Playlist"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.register(UINib(nibName: "CreatePlaylistCell", bundle: nil), forCellReuseIdentifier: "Cell")
        
        self.tableView.reloadData()
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel",
            style: .plain,
            target: self,
            action: #selector(CreatePlaylistOverlay.dismiss as (CreatePlaylistOverlay) -> () -> ()))
    
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Done",
            style: .plain,
            target: self,
            action: #selector(CreatePlaylistOverlay.createPlaylist))
        
        let nib = UINib(nibName: "CreatePlaylistCell",
            bundle: nil)
        self.createPlaylistCell = nib.instantiate(withOwner: self, options: nil)[0] as! CreatePlaylistCell
        self.createPlaylistCell.delegate = self
        
        if let _ = self.artist {
            self.createPlaylistCell.smartSwitch.isEnabled = true
        } else {
            self.createPlaylistCell.smartSwitch.isEnabled = false
        }
    }
    
    fileprivate func requestSimiliarArtists() {
        let similiarArtistLastFmRequest = LastFmSimiliarArtistsRequest(artist: self.artist)
        similiarArtistLastFmRequest.delegate = self
        similiarArtistLastFmRequest.sendURLRequest()
    }
    
    func lastFmSimiliarArtistsRequestDidComplete(_ request: LastFmSimiliarArtistsRequest,
        didCompleteWithLastFmArtists artists: [AnyObject]?) {
        let index = self.createPlaylistCell.amountSegmentedControl.selectedSegmentIndex
        let amount = Int(self.createPlaylistCell.amountSegmentedControl.titleForSegment(at: index)!)!
        let name = self.createPlaylistCell.nameTextField.text
        let playlistType = PlaylistType.smart
        MediaSession.sharedSession.dataManager.datastore.createPlaylistWithSimiliarArtists(self.artist,
            artists: artists,
            fetchLimit: amount,
            name: name,
            playlistType: playlistType) { (addedSongs) -> () in
            self.handleCreatePlaylistFinishWithAddedSongs(addedSongs)
        }
    }
    
    func dismiss() {
        self.dismiss(animated: true, completion: nil)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 1 {
            self.createPlaylistCell.selectionStyle = .none
            return self.createPlaylistCell
        } else {
            let cell = UITableViewCell(style: .default, reuseIdentifier: "Cell")
            if let playlist = self.existingPlaylist {
                cell.textLabel?.text = playlist.name
            } else {
                cell.textLabel?.text = "Add to existing playlist"
            }
            cell.textLabel?.font = MuzSettingFont
            cell.textLabel?.textColor = UIColor.white
            cell.accessoryType = .disclosureIndicator
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 1 {
            return CreatePlaylistCellHeight
        } else {
            return 45.0
        }
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 1 {
            
        } else {
            if self.artist == nil {
                UIAlertView(title: "Error!",
                    message: "You haven't selected anything to add to an existing playlist.",
                    delegate: self,
                    cancelButtonTitle: "Ok").show()
            } else {
                let playlistsViewController = PlaylistsViewController(existingPlaylist: true)
                playlistsViewController.delegate = self
                self.navigationController?.pushViewController(playlistsViewController, animated: true)
            }
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }

    // MARK: CreatePlaylistCellDelegate
    func createPlaylistCell(_ cell: CreatePlaylistCell, didStartEditing textField: UITextField!) {
        
    }
    
    func createPlaylistCell(_ cell: CreatePlaylistCell, shouldReturn textField: UITextField!) {
        self.createPlaylist()
    }

    func createPlaylist() {
        if self.createPlaylistCell.smartSwitch.isOn {
            self.hud = MBProgressHUD.showAdded(to: self.view, animated: true)
            self.hud.mode = .indeterminate
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
                    if self.createPlaylistCell.nameTextField.text?.characters.count > 0 {
                        if let songs = self.songs {
                            MediaSession.sharedSession.dataManager.datastore.createPlaylistWithSongs(self.createPlaylistCell.nameTextField.text!,
                                songs: songs,
                                completion: { (addedSongs) -> () in
                                self.dismiss()
                            })
                        } else {
                            MediaSession.sharedSession.dataManager.datastore.createPlaylistWithArtist(self.artist,
                                name: self.createPlaylistCell.nameTextField.text,
                                playlistType: .none) { (addedSongs) -> () in
                                    self.dismiss()
                            }
                        }
                    } else {
                        showEmptyPlaylistNameAlert()
                    }
                }
            } else {
                if self.createPlaylistCell.nameTextField.text?.characters.count > 0 {
                    MediaSession.sharedSession.dataManager.datastore.createEmptyPlaylistWithName(self.createPlaylistCell.nameTextField.text!,
                        playlistType: .none) { () -> () in
                            self.dismiss()
                    }
                } else {
                    showEmptyPlaylistNameAlert()
                }
                
            }
        }
    }
    
    fileprivate func showEmptyPlaylistNameAlert() {
        UIAlertView(title: "Error!",
            message: "You must set a playlist name!",
            delegate: self,
            cancelButtonTitle: "Ok").show()
    }
    
    fileprivate func handleCreatePlaylistFinishWithAddedSongs(_ addedSongs: [AnyObject]?) {
        if let _ = addedSongs {
            self.dismiss()
        } else {
            let errorMessage = "Unable to find any songs based on \(self.artist)"
            UIAlertView(title: "Error!",
                message: errorMessage,
                delegate: self,
                cancelButtonTitle: "Ok").show()
            self.hud.hide(true)
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.createPlaylistCell.nameTextField.resignFirstResponder()
    }
    
    func playlistsViewController(_ controller: PlaylistsViewController, didSelectPlaylist playlist: Playlist) {
        self.existingPlaylist = playlist
        self.tableView.reloadData()
        
        self.createPlaylistCell.smartSwitch.isOn = false
        self.createPlaylistCell.smartSwitchDidChange(self.createPlaylistCell.smartSwitch)
        self.createPlaylistCell.smartSwitch.isEnabled = false
        self.createPlaylistCell.nameTextField.text = ""
        self.createPlaylistCell.nameTextField.isEnabled = false
    }
}
