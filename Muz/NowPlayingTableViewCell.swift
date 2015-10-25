//
//  NowPlayingTableViewCell.swift
//  Muz
//
//  Created by Nickolas Lanasa on 2/8/15.
//  Copyright (c) 2015 Nytek Productions. All rights reserved.
//

import Foundation
import UIKit
import MediaPlayer

class NowPlayingTableViewCell: UITableViewCell {
    @IBOutlet weak var songImageView: UIImageView!
    @IBOutlet weak var artistLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var progressView: UIProgressView!
    
    var updateTimer: NSTimer!
    let playerController = MPMusicPlayerController.iPodMusicPlayer()
    
    override func awakeFromNib() {
        updateTimer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: "updateProgress", userInfo: nil, repeats: true)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: "pausePlay")
        tapGesture.numberOfTapsRequired = 1
        self.songImageView.gestureRecognizers = [tapGesture]
        
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "playerControllerDidNowPlayingItemDidChange",
            name: MPMusicPlayerControllerNowPlayingItemDidChangeNotification,
            object: nil)
        
        if playerController.nowPlayingItem == nil {
            self.songImageView.alpha = 0.0
            self.artistLabel.alpha = 0.0
            self.titleLabel.alpha = 0.0
            self.progressView.alpha = 0.0
        }
        
        self.updateNowPlaying()
    }
    
    func playerControllerDidNowPlayingItemDidChange() {
        if let _ = self.playerController.nowPlayingItem {
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.updateNowPlaying()
            })
        }
    }
    
    func updateProgress() {
        if let item = playerController.nowPlayingItem {
            progressView.progress = (Float(self.playerController.currentPlaybackTime) / Float(item.playbackDuration))
        }
    }
    
    func updateNowPlaying() {
        if let item = playerController.nowPlayingItem {
            if let title = item.title, let artist = item.artist {
                DataManager.manager.datastore.songForSongName(title, artist: artist, completion: { (song) -> () in
                    if let newSong = song {
                        self.songImageView.alpha = 1.0
                        self.artistLabel.alpha = 1.0
                        self.titleLabel.alpha = 1.0
                        self.songImageView.setImageForSong(song: newSong)
                        self.artistLabel.text = newSong.artist
                        self.titleLabel.text = newSong.title
                    }
                })
            } else {
                UIAlertView(title: "Error!",
                    message: "Unable to find song!",
                    delegate: self,
                    cancelButtonTitle: "Ok").show()
            }
        }
    }
    
    func pausePlay() {
        if playerController.playbackState == .Playing {
            playerController.stop()
        } else {
            playerController.play()
        }
    }
}