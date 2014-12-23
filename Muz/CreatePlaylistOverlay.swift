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
LastFmSimiliarArtistsRequestDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    var createPlaylistCell: CreatePlaylistCell!
    var artist: NSString!
    var item: MPMediaItem!
    var hud: MBProgressHUD!
    
    override init() {
        super.init(nibName: "CreatePlaylistOverlay", bundle: nil)
    }
    
    init(artist: NSString!) {
        self.artist = artist
        super.init(nibName: "CreatePlaylistOverlay", bundle: nil)
    }
    
    init(item: MPMediaItem!) {
        self.item = item
        self.artist = item.artist
        super.init(nibName: "CreatePlaylistOverlay", bundle: nil)
    }
    
    override func viewWillAppear(animated: Bool) {
        createPlaylistCell.nameTextField.becomeFirstResponder()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.registerNib(UINib(nibName: "CreatePlaylistCell", bundle: nil), forCellReuseIdentifier: "Cell")
        
        self.navigationItem.title = "New Playlist"
        
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
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        return createPlaylistCell
    }
    
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    
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
            createPlaylistWithArtist()
        }
    }
    
    func createPlaylistWithArtist() {
        let name = createPlaylistCell.nameTextField.text
        let playlistType = PlaylistType.None
        MediaSession.sharedSession.dataManager.datastore.createPlaylistWithArtist(self.artist,
            name: name,
            playlistType: playlistType) { (addedSongs) -> () in
            self.handleCreatePlaylistFinishWithAddedSongs(addedSongs)
        }
    }
    
    private func handleCreatePlaylistFinishWithAddedSongs(addedSongs: [AnyObject]?) {
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            if let songsAdded = addedSongs {
                self.dismiss()
            } else {
                let errorMessage = "Unable to find any songs based on \(self.artist)"
                UIAlertView(title: "Error!", message: errorMessage, delegate: self, cancelButtonTitle: "Ok").show()
            }
        })
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        createPlaylistCell.nameTextField.resignFirstResponder()
    }
}