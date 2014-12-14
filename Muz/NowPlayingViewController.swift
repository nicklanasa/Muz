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
import MediaPlayer

class NowPlayingViewController: RootViewController {
    
    var song: Song!
    var songTimer: NSTimer?
    var collection: MPMediaItemCollection?
    var indexOfCurrentlyPlayingSong = 1
    var pinchGesture: UIPinchGestureRecognizer!
    
    lazy var nowPlayingInfoController: NowPlayingInfoViewController = {
        var nowPlayingInfoViewController = NowPlayingInfoViewController()
        return nowPlayingInfoViewController
    }()
    
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
        let albumPredicate = MPMediaPropertyPredicate(value: song.albumTitle, forProperty: MPMediaItemPropertyAlbumTitle, comparisonType: .EqualTo)
        
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
            updateView(item)
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
        
        self.tabBarItem = UITabBarItem(title: "",
            image: UIImage(named: "headphones"),
            selectedImage: UIImage(named: "headphones"))
        self.tabBarItem.imageInsets = UIEdgeInsetsMake(6, 0, -6, 0)
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
        
        pinchGesture = UIPinchGestureRecognizer(target: self, action: "showInfoController:")
        view.addGestureRecognizer(pinchGesture)
        
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
        
        addChildViewController(nowPlayingInfoController)
        nowPlayingInfoController.didMoveToParentViewController(self)
        view.insertSubview(nowPlayingInfoController.view, belowSubview: self.view)
        
        nowPlayingInfoController.view.alpha = 0.0
    }
    
    func showInfoController(gesture: UIPinchGestureRecognizer) {
        view.removeGestureRecognizer(gesture)
        UIView.animateWithDuration(0.3, animations: { () -> Void in
            self.artwork.alpha = 0.0
            self.songLabel.alpha = 0.0
            self.progressView.alpha = 0.0
            
            UIView.animateWithDuration(0.3, animations: { () -> Void in
                self.nowPlayingInfoController.view.alpha = 1.0
                
                self.pinchGesture = UIPinchGestureRecognizer(target: self, action: "hideInfoController:")
                self.view.addGestureRecognizer(self.pinchGesture)
            })
            
        })
    }
    
    func hideInfoController(gesture: UIPinchGestureRecognizer) {
        view.removeGestureRecognizer(gesture)
        UIView.animateWithDuration(0.3, animations: { () -> Void in
            
            self.nowPlayingInfoController.view.alpha = 0.0
            
            UIView.animateWithDuration(0.3, animations: { () -> Void in
                self.artwork.alpha = 1.0
                self.songLabel.alpha = 1.0
                self.progressView.alpha = 1.0
                
                var pinchGesture = UIPinchGestureRecognizer(target: self, action: "showInfoController:")
                self.view.addGestureRecognizer(pinchGesture)
            })
            
        })
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
        if let item = playerController.nowPlayingItem {
            updateView(item)
        }
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
        
        if indexOfCurrentlyPlayingSong < collection?.items.count {
            if let item = collection?.items[indexOfCurrentlyPlayingSong] as? MPMediaItem {
                updateNowPlayingWithItem(item)
            }
        }
    }
    
    func updateView(item: MPMediaItem) {
        let noArtwork = UIImage(named: "noArtwork")
        let delegate = UIApplication.sharedApplication().delegate as AppDelegate
        
        if let artwork = item.artwork {
            if let image = artwork.imageWithSize(CGSize(width:500, height:500)) {
                self.artwork.image = image
                delegate.currentAppBackgroundImage = image
            } else {
                self.artwork.image = noArtwork
                delegate.currentAppBackgroundImage = noArtwork!
            }
        } else {
            self.artwork.image = noArtwork
            delegate.currentAppBackgroundImage = noArtwork!
        }
        
        self.backgroundImageView.image = delegate.currentAppBackgroundImage.applyDarkEffect()
        
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
        updateView(item)
        nowPlayingInfoController.updateWithItem(item)
    }
    
    func startSongTimer() {
        songTimer = NSTimer.scheduledTimerWithTimeInterval(0.4,
            target: self,
            selector: Selector("updateProgress"),
            userInfo: nil,
            repeats: true)
    }
}