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
        
        var tapGesture = UITapGestureRecognizer(target: self, action: "pausePlay")
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
        if let item = self.playerController.nowPlayingItem {
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.updateNowPlaying()
            })
        }
    }
    
    func updateProgress() {
        if let item = playerController.nowPlayingItem {
            progressView.progress = (Float(self.playerController.currentPlaybackTime) / Float(item.playbackDuration))
            print("\nCurrent song progress value: \(progressView.progress)\n")
        }
    }
    
    func updateNowPlaying() {
        if let item = playerController.nowPlayingItem {
            var manager = DataManager.manager
            if let song = manager.datastore.songForSongName(item.title, artist: item.artist) {
                self.songImageView.alpha = 1.0
                self.artistLabel.alpha = 1.0
                self.titleLabel.alpha = 1.0
                self.songImageView.setImageForSong(song: song)
                self.artistLabel.text = song.artist
                self.titleLabel.text = song.title
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