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

class NowPlayingViewController: RootViewController,
NowPlayingCollectionControllerDelegate {
    
    let playerController = MPMusicPlayerController.iPodMusicPlayer()
    
    var song: Song!
    var item: MPMediaItem!
    var collection: MPMediaItemCollection?
    var isLandscaped = false
    
    private var pinchGesture: UIPinchGestureRecognizer!
    private var songTimer: NSTimer?
    
    @IBOutlet weak var artwork: UIImageView!
    @IBOutlet weak var songLabel: UILabel!
    @IBOutlet weak var shuffleButton: UIButton!
    @IBOutlet weak var repeatButton: UIButton!
    @IBOutlet weak var infoButton: UIButton!
    @IBOutlet weak var progressSlider: UISlider!
    @IBOutlet weak var tutorialView: UIView!
    
    override init() {
        super.init(nibName: "NowPlayingViewController", bundle: nil)
        
        self.tabBarItem = UITabBarItem(title: "",
            image: UIImage(named: "headphones"),
            selectedImage: UIImage(named: "headphones"))
        self.tabBarItem.imageInsets = UIEdgeInsetsMake(6, 0, -6, 0)
    }
    
    init(song: Song) {
        super.init(nibName: "NowPlayingViewController", bundle: nil)
        
        self.song = song
        
        configureWithSong()
        
        self.tabBarItem.imageInsets = UIEdgeInsetsMake(6, 0, -6, 0)
    }
    
    override func viewWillAppear(animated: Bool) {
        if self.item == nil && playerController.nowPlayingItem != nil {
            self.item = playerController.nowPlayingItem
            
            if playerController.playbackState != .Playing {
                configureWithSong()
            } else {
                updateNowPlaying()
            }
        }
        
        self.screenName = "Now Playing"
        self.navigationItem.title = ""
        
        super.viewWillAppear(animated)
    }
    
    private func configureWithSong() {
        if let song = self.song {
            if let item = DataManager.manager.fetchItemForSong(song: song) {
                self.item = item
                self.updateNowPlaying()
            }
        }
    }

    func playSong(song: Song, collection: MPMediaItemCollection) {
        self.song = song
        self.item = DataManager.manager.fetchItemForSong(song: song)
        self.collection = collection
        self.playerController.setQueueWithItemCollection(collection)
        self.playerController.play()
        updateNowPlaying()
    }
    
    func playItem(item: MPMediaItem) {
        self.item = item
        configureWithSong()
        playerController.play()
    }
    
    func playItem(item: MPMediaItem, collection: MPMediaItemCollection) {
        self.item = item
        self.collection = collection
        self.playerController.setQueueWithItemCollection(collection)
        self.playerController.play()
        self.updateNowPlaying()
    }
    
    private func startSongTimer() {
        songTimer = NSTimer.scheduledTimerWithTimeInterval(0.4,
            target: self,
            selector: Selector("updateProgress"),
            userInfo: nil,
            repeats: true)
    }
    
    func updateProgress() {
        if let currentlyPlayingSong = self.song {
            progressSlider.value = Float(playerController.currentPlaybackTime) / currentlyPlayingSong.playbackDuration.floatValue
        }
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        var swipeLeftGesture = UISwipeGestureRecognizer(target: self, action: "nextSong")
        swipeLeftGesture.direction = .Left
        view.addGestureRecognizer(swipeLeftGesture)
        
        var swipeRightGesture = UISwipeGestureRecognizer(target: self, action: "previousSong")
        swipeRightGesture.direction = .Right
        view.addGestureRecognizer(swipeRightGesture)
        
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
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "list"),
            style: .Plain,
            target: self,
            action: "showNowPlayingCollectionController")
        
        progressSlider.setThumbImage(UIImage(named: "thumbImage"), forState: .Normal)
        progressSlider.setThumbImage(UIImage(named: "thumbImage"), forState: .Selected)
    }
    
    func showNowPlayingCollectionController() {
        
        let nowPlayingCollectionController = NowPlayingCollectionController(collection: collection)
        nowPlayingCollectionController.delegate = self
        
        presentModalOverlayController(nowPlayingCollectionController, blurredController: self)
    }
    
    func applicationDidEnterBackground() {
        //xplayerController.endGeneratingPlaybackNotifications()
    }
    
    // MARK: MPMusicPlayerController
    
    func playPause() {
        if self.playerController.playbackState == .Playing {
            self.playerController.pause()
        } else {
            self.playerController.play()
        }
    }
    
    func playerControllerDidNowPlayingItemDidChange() {
        if let item = self.playerController.nowPlayingItem {
            self.item = item
            self.updateView()
        }
    }
    
    func nextSong() {
        if self.playerController.repeatMode == .One {
            self.updateNowPlaying()
            self.playerController.stop()
            self.playerController.play()
        } else {
            
            let artworkCenter = self.artwork.center
            let songLabelCenter = self.songLabel.center
            
            UIView.animateWithDuration(0.15, animations: { () -> Void in
                self.songLabel.frame = CGRectMake(0 - self.songLabel.frame.size.width,
                    self.songLabel.frame.origin.y, self.songLabel.frame.size.width, self.songLabel.frame.size.height)
                self.artwork.frame = CGRectMake(0 - self.artwork.frame.size.width,
                    self.artwork.frame.origin.y, self.artwork.frame.size.width, self.artwork.frame.size.height)
                
                self.songLabel.alpha = 0.0
                self.artwork.alpha = 0.0
                
                self.playerController.skipToNextItem()
                
                }, completion: { (success) -> Void in
                    
                    self.songLabel.frame = CGRectMake(UIScreen.mainScreen().bounds.width + self.songLabel.frame.size.width,
                        self.songLabel.frame.origin.y, self.songLabel.frame.size.width, self.songLabel.frame.size.height)
                    self.artwork.frame = CGRectMake(UIScreen.mainScreen().bounds.width + self.artwork.frame.size.width,
                        self.artwork.frame.origin.y, self.artwork.frame.size.width, self.artwork.frame.size.height)
                    
                    UIView.animateWithDuration(0.15, animations: { () -> Void in
                        
                        self.songLabel.alpha = 1.0
                        self.artwork.alpha = 1.0
                        
                        self.songLabel.center = songLabelCenter
                        self.artwork.center = artworkCenter
                    })
            })
        }
    }
    
    func previousSong() {
        if playerController.repeatMode == .One {
            
            self.updateNowPlaying()
            
            self.playerController.stop()
            self.playerController.play()
        } else {
            let artworkCenter = self.artwork.center
            let songLabelCenter = self.songLabel.center
            
            UIView.animateWithDuration(0.15, animations: { () -> Void in
                self.songLabel.frame = CGRectMake(UIScreen.mainScreen().bounds.width +  self.songLabel.frame.size.width,
                    self.songLabel.frame.origin.y, self.songLabel.frame.size.width, self.songLabel.frame.size.height)
                self.artwork.frame = CGRectMake(UIScreen.mainScreen().bounds.width +  self.artwork.frame.size.width,
                    self.artwork.frame.origin.y, self.artwork.frame.size.width, self.artwork.frame.size.height)
                
                self.songLabel.alpha = 0.0
                self.artwork.alpha = 0.0
                
                self.playerController.skipToPreviousItem()
                
                }, completion: { (success) -> Void in
                    
                    self.songLabel.frame = CGRectMake(0 - self.songLabel.frame.size.width,
                        self.songLabel.frame.origin.y, self.songLabel.frame.size.width, self.songLabel.frame.size.height)
                    self.artwork.frame = CGRectMake(0 - self.artwork.frame.size.width,
                        self.artwork.frame.origin.y, self.artwork.frame.size.width, self.artwork.frame.size.height)
                    
                    UIView.animateWithDuration(0.15, animations: { () -> Void in
                        
                        self.songLabel.alpha = 1.0
                        self.artwork.alpha = 1.0
                        
                        self.songLabel.center = songLabelCenter
                        self.artwork.center = artworkCenter
                    })
            })
        }
    }

    // MARK: Updating
    
    func showInfoController(gesture: UIPinchGestureRecognizer?) {
        UIView.animateWithDuration(0.3, animations: { () -> Void in
            UIView.animateWithDuration(0.3, animations: { () -> Void in
                self.hideNowPlayingViews()
            })
        })
    }
    
    func hideInfoController(gesture: UIPinchGestureRecognizer?) {
        UIView.animateWithDuration(0.3, animations: { () -> Void in
            self.showNowPlayingViews()
        })
    }
    
    private func hideNowPlayingViews() {
        UIView.animateWithDuration(0.3, animations: { () -> Void in
            self.artwork.alpha = 0.0
            self.songLabel.alpha = 0.0
            self.progressSlider.alpha = 0.0
            self.shuffleButton.alpha = 0.0
            self.repeatButton.alpha = 0.0
            self.infoButton.alpha = 0.0
        })
    }
    
    private func showNowPlayingViews() {
        UIView.animateWithDuration(0.3, animations: { () -> Void in
            self.artwork.alpha = 1.0
            self.songLabel.alpha = 1.0
            self.progressSlider.alpha = 1.0
            
            self.shuffleButton.alpha = 1.0
            self.repeatButton.alpha = 1.0
            self.infoButton.alpha = 1.0
        })
    }
    
    private func updateView() {
        
        showNowPlayingViews()
        
        let noArtwork = UIImage(named: "noArtwork")
        if let artwork = self.item.artwork {
            if let image = artwork.imageWithSize(CGSize(width:500, height:500)) {
                self.artwork.image = image
                CurrentAppBackgroundImage = image
            } else {
                self.artwork.image = noArtwork
                CurrentAppBackgroundImage = noArtwork!
            }
        } else {
            self.artwork.image = noArtwork
            CurrentAppBackgroundImage = noArtwork!
        }
        
        self.backgroundImageView.image = CurrentAppBackgroundImage.applyDarkEffect()
        
        let songInfo = NSString(format: "%@\n%@\n%@", self.item.title, self.item.artist, self.item.albumTitle)
        let attributedSongInfo = NSMutableAttributedString(string: songInfo)
        let songFont = UIFont(name: MuzFontName, size: 35)!
        let artistFont = UIFont(name: MuzFontNameRegular, size: 18)!
        attributedSongInfo.addAttribute(NSFontAttributeName,
            value: songFont,
            range: NSMakeRange(0, countElements(self.item.title)))
        attributedSongInfo.addAttribute(NSFontAttributeName,
            value: artistFont,
            range: NSMakeRange(countElements(self.item.title),
                countElements(self.item.artist) + 1))
        self.songLabel.attributedText = attributedSongInfo
        
        if let timer = songTimer {
            timer.invalidate()
        }
        
        startSongTimer()
        
        progressSlider.hidden = false
    }
    
    private func updateNowPlaying() {
        
        playerController.nowPlayingItem = self.item
        
        self.updateView()
        
        if NSUserDefaults.standardUserDefaults().objectForKey("Tutorial") == nil {
            tutorialView.alpha = 0.85
            
            let tapGesture = UITapGestureRecognizer(target: self, action: "dismissTutorial")
            tapGesture.numberOfTapsRequired = 1
            tutorialView.addGestureRecognizer(tapGesture)
            NSUserDefaults.standardUserDefaults().setObject(NSNumber(bool: false), forKey: "Tutorial")
        } else {
            tutorialView.alpha = 0.0
        }
    }
    
    func dismissTutorial() {
        UIView.animateWithDuration(0.3, animations: { () -> Void in
            self.tutorialView.alpha = 0.0
            self.tutorialView.removeFromSuperview()
        })
    }
    
    // MARK: IBAction
    
    @IBAction func progressSliderValueChanged(sender: AnyObject) {
        if let currentPlayingSong = self.song {
            playerController.currentPlaybackTime = Double(progressSlider.value) * currentPlayingSong.playbackDuration.doubleValue
        }
    }
    
    @IBAction func infoButtonPressed(sender: AnyObject) {
        if let item = self.item {
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                var controller = NowPlayingInfoViewController(item: self.item)
                self.navigationController?.pushViewController(controller, animated: true)
            })
        } else {
            UIAlertView(title: "Error!",
                message: "You must be listening to a track to see info.",
                delegate: self,
                cancelButtonTitle: "Ok").show()
        }
    }
    
    @IBAction func shuffleButtonPressed(sender: AnyObject) {
        if playerController.shuffleMode == .Songs {
            playerController.shuffleMode = .Off
            shuffleButton.setTitleColor(MuzColor, forState: .Normal)
        } else {
            playerController.shuffleMode = .Songs
            shuffleButton.setTitleColor(MuzBlueColor, forState: .Normal)
        }
    }
    
    @IBAction func repeatButtonPressed(sender: AnyObject) {
        UIView.animateWithDuration(0.3, animations: { () -> Void in
            if self.playerController.repeatMode == .One {
                self.playerController.repeatMode = .None
                self.repeatButton.setTitleColor(MuzColor, forState: .Normal)
                self.repeatButton.setTitle("Repeat", forState: .Normal)
            } else if self.playerController.repeatMode == .All {
                self.playerController.repeatMode = .One
                self.repeatButton.setTitleColor(MuzBlueColor, forState: .Normal)
                self.repeatButton.setTitle("Repeat", forState: .Normal)
            } else {
                self.playerController.repeatMode = .All
                self.repeatButton.setTitleColor(MuzBlueColor, forState: .Normal)
                self.repeatButton.setTitle("Repeat All", forState: .Normal)
            }
        })
    }
    
    
    func nowPlayingCollectionController(controller: NowPlayingCollectionController,
        didSelectItem item: MPMediaItem) {
        playerController.stop()
        playerController.nowPlayingItem = item
        playerController.play()
    }
    
    override func willRotateToInterfaceOrientation(toInterfaceOrientation: UIInterfaceOrientation, duration: NSTimeInterval) {
        super.willRotateToInterfaceOrientation(toInterfaceOrientation, duration: duration)
        if toInterfaceOrientation == .LandscapeLeft || toInterfaceOrientation == .LandscapeRight {
            var landscapeNowPlaying = NowPlayingViewControllerLandscape()
            self.navigationController?.pushViewController(landscapeNowPlaying, animated: false)
            landscapeNowPlaying.updateNowPlayingWithItem(self.item)
        }
    }
    
    override func didRotateFromInterfaceOrientation(fromInterfaceOrientation: UIInterfaceOrientation) {
        super.didRotateFromInterfaceOrientation(fromInterfaceOrientation)
    }
}