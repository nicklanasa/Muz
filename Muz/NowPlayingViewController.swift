//
//  NowPlayingViewController.swift
//  Muz
//
//  Created by Nick Lanasa on 12/9/14.
//  Copyright (c) 2014 Nytek Productions. All rights reserved.
//

import Foundation
import UIKit
import CoreData
import AVFoundation
import MediaPlayer

class NowPlayingViewController: RootViewController {
    
    var song: Song!
    var songTimer: NSTimer?
    var collection: MPMediaItemCollection?
    var indexOfCurrentlyPlayingSong = 1
    
    @IBOutlet weak var artwork: UIImageView!
    @IBOutlet weak var songLabel: UILabel!
    @IBOutlet weak var progressView: UIProgressView!
    
    let playerController = MPMusicPlayerController.iPodMusicPlayer()
    
    init(song: Song) {
        self.song = song
        super.init(nibName: "NowPlayingViewController", bundle: nil)
        
        configureWithSong()
    }
    
    private func configureWithSong() {
        
        // Get MPMediaItem
        var query = MPMediaQuery.songsQuery()
        let titlePredicate = MPMediaPropertyPredicate(value: song.title, forProperty: MPMediaItemPropertyTitle, comparisonType: .Contains)
        let artistPredicate = MPMediaPropertyPredicate(value: song.artist, forProperty: MPMediaItemPropertyArtist, comparisonType: .Contains)
        let albumPredicate = MPMediaPropertyPredicate(value: song.albumTitle, forProperty: MPMediaItemPropertyAlbumTitle, comparisonType: .Contains)
        
        query.addFilterPredicate(titlePredicate)
        query.addFilterPredicate(artistPredicate)
        query.addFilterPredicate(albumPredicate)
        
        if let item = query.items.first as? MPMediaItem {
            
            query = MPMediaQuery()
            query.addFilterPredicate(albumPredicate)
            
            if let items = query.items as? [MPMediaItem] {
                collection = MPMediaItemCollection(items: items)
                playerController.setQueueWithItemCollection(collection)
            }
        
            indexOfCurrentlyPlayingSong = item.albumTrackNumber
            updateNowPlayingWithItem(item)
        }
    }
    
    func updateProgress() {
        if let s = song {
            progressView.progress = Float(playerController.currentPlaybackTime) / song.playbackDuration.floatValue
        }
    }
    
    func playSong(song: Song) {
        self.song = song
        configureWithSong()
    }
    
    override init() {
        super.init(nibName: "NowPlayingViewController", bundle: nil)
        
        self.tabBarItem = UITabBarItem(title: "Now Playing",
            image: UIImage(named: "headphones"),
            selectedImage: UIImage(named: "headphones"))
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        var swipeUpGesture = UISwipeGestureRecognizer(target: self, action: "nextSong")
        swipeUpGesture.direction = .Up
        view.addGestureRecognizer(swipeUpGesture)
        
        var swipeDownGesture = UISwipeGestureRecognizer(target: self, action: "previousSong")
        swipeDownGesture.direction = .Down
        view.addGestureRecognizer(swipeDownGesture)
        
        var tapGesture = UITapGestureRecognizer(target: self, action: "playPause")
        tapGesture.numberOfTapsRequired = 1
        artwork.addGestureRecognizer(tapGesture)
        
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "playPause",
            name: UIApplicationWillTerminateNotification,
            object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "applicationDidEnterBackground",
            name: UIApplicationDidEnterBackgroundNotification,
            object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "playerControllerDidNowPlayingItemDidChange",
            name: MPMusicPlayerControllerNowPlayingItemDidChangeNotification,
            object: nil)
        
        playerController.beginGeneratingPlaybackNotifications()
    }
    
    func applicationDidEnterBackground() {
        playerController.endGeneratingPlaybackNotifications()
    }
    
    func nextSong() {
        indexOfCurrentlyPlayingSong++
        updateNowPlayingItem()
    }
    
    func previousSong() {
        indexOfCurrentlyPlayingSong--
        updateNowPlayingItem()
    }
    
    func playPause() {
        if playerController.playbackState == .Playing {
            playerController.pause()
        } else {
            playerController.play()
        }
    }
    
    func playerControllerDidNowPlayingItemDidChange() {
        updateView(playerController.nowPlayingItem)
    }
    
    func updateNowPlayingItem() {
        
        if indexOfCurrentlyPlayingSong > collection?.items.count {
            indexOfCurrentlyPlayingSong = 0
        } else if indexOfCurrentlyPlayingSong <= 0 {
            if let items = collection?.items as? [MPMediaItem] {
                indexOfCurrentlyPlayingSong = collection!.items.count - 1
            } else {
                indexOfCurrentlyPlayingSong = 0
            }
            
        }
        
        if let item = collection?.items[indexOfCurrentlyPlayingSong] as? MPMediaItem {
            updateNowPlayingWithItem(item)
        }
    }
    
    func updateView(item: MPMediaItem) {
        let noArtwork = UIImage(named: "noArtwork")
        
        if let artwork = item.artwork {
            if let image = artwork.imageWithSize(CGSize(width:500, height:500)) {
                self.artwork.image = image
                self.backgroundImageView.image = image.applyDarkEffect()
            } else {
                self.artwork.image = noArtwork
                self.backgroundImageView.image = noArtwork!.applyDarkEffect()
            }
        } else {
            self.artwork.image = noArtwork
            self.backgroundImageView.image = noArtwork!.applyDarkEffect()
        }
        
        let songInfo = NSString(format: "%@\n%@\n%@", item.title, item.artist, item.albumTitle)
        let attributedSongInfo = NSMutableAttributedString(string: songInfo)
        let songFont = UIFont(name: MuzFontName, size: 40)!
        let artistFont = UIFont(name: MuzFontName, size: 17)!
        attributedSongInfo.addAttribute(NSFontAttributeName, value: songFont, range: NSMakeRange(0, countElements(item.title)))
        self.songLabel.attributedText = attributedSongInfo
        
        if let timer = songTimer {
            timer.invalidate()
        }
        
        startSongTimer()
        
        progressView.hidden = false
    }
    
    func updateNowPlayingWithItem(item: MPMediaItem) {
        playerController.nowPlayingItem = item
        playerController.play()
    }
    
    func startSongTimer() {
        songTimer = NSTimer.scheduledTimerWithTimeInterval(0.4,
            target: self,
            selector: Selector("updateProgress"),
            userInfo: nil,
            repeats: true)
    }
}