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
    
    var item: MPMediaItem!
    private var songTimer: NSTimer?
    var collection: MPMediaItemCollection?
    private var pinchGesture: UIPinchGestureRecognizer!
    var isLandscaped = false
    
    @IBOutlet weak var artwork: UIImageView!
    @IBOutlet weak var songLabel: UILabel!
    @IBOutlet weak var shuffleButton: UIButton!
    @IBOutlet weak var repeatButton: UIButton!
    @IBOutlet weak var infoButton: UIButton!
    @IBOutlet weak var progressSlider: UISlider!
    @IBOutlet weak var tutorialView: UIView!
    
    let playerController = MPMusicPlayerController.iPodMusicPlayer()
    
    init(song: Song) {
        super.init(nibName: "NowPlayingViewController", bundle: nil)
        configureWithItem()
    }
    
    @IBAction func progressSliderValueChanged(sender: AnyObject) {
        if let currentlyPlayingItem = item {
            playerController.currentPlaybackTime = Double(progressSlider.value) * currentlyPlayingItem.playbackDuration
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        if self.item == nil && playerController.nowPlayingItem != nil {
            self.item = playerController.nowPlayingItem
            
            if playerController.playbackState != .Playing {
                configureWithItem()
            } else {
                updateNowPlayingWithItem(self.item)
            }
        }
        
        self.screenName = "Now Playing"
        self.navigationItem.title = ""
        
        super.viewWillAppear(animated)
    }
    
    private func configureWithItem() {
        // Get MPMediaItem
        var query = MPMediaQuery.songsQuery()
        let titlePredicate = MPMediaPropertyPredicate(value: item.title, forProperty: MPMediaItemPropertyTitle, comparisonType: .Contains)
        let artistPredicate = MPMediaPropertyPredicate(value: item.artist, forProperty: MPMediaItemPropertyArtist, comparisonType: .Contains)
        let albumPredicate = MPMediaPropertyPredicate(value: item.albumTitle, forProperty: MPMediaItemPropertyAlbumTitle, comparisonType: .EqualTo)
        
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
            
            updateNowPlayingWithItem(item)
        }
    }

    func updateProgress() {
        if let currentlyPlayingItem = item {
            progressSlider.value = Float(playerController.currentPlaybackTime) / Float(currentlyPlayingItem.playbackDuration)
        }
    }
    
    func playItem(item: MPMediaItem) {
        self.item = item
        configureWithItem()
        playerController.play()
    }
    
    func playItem(item: MPMediaItem, collection: MPMediaItemCollection) {
        self.item = item
        self.collection = collection
        playerController.setQueueWithItemCollection(collection)
        playerController.play()
        updateNowPlayingWithItem(self.item)
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
    
    func applicationDidEnterBackground() {
        playerController.endGeneratingPlaybackNotifications()
    }
    
    func nextSong() {
        if playerController.repeatMode == .One {
            updateNowPlayingWithItem(self.item)
            
            playerController.stop()
            playerController.play()
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
            updateNowPlayingWithItem(self.item)
            playerController.stop()
            playerController.play()
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
    
    func playPause() {
        if playerController.playbackState == .Playing {
            playerController.pause()
        } else {
            playerController.play()
        }
    }
    
    func playerControllerDidNowPlayingItemDidChange() {
        if let item = playerController.nowPlayingItem {
            self.item = item
            updateView(self.item)
        }
    }
    
    private func updateView(item: MPMediaItem) {
        
        showNowPlayingViews()
        
        let noArtwork = UIImage(named: "noArtwork")
        if let artwork = item.artwork {
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
        
        let songInfo = NSString(format: "%@\n%@\n%@", item.title, item.artist, item.albumTitle)
        let attributedSongInfo = NSMutableAttributedString(string: songInfo)
        let songFont = UIFont(name: MuzFontName, size: 35)!
        let artistFont = UIFont(name: MuzFontNameRegular, size: 18)!
        attributedSongInfo.addAttribute(NSFontAttributeName, value: songFont, range: NSMakeRange(0, countElements(item.title)))
        attributedSongInfo.addAttribute(NSFontAttributeName, value: artistFont, range: NSMakeRange(countElements(item.title), countElements(item.artist) + 1))
        self.songLabel.attributedText = attributedSongInfo
        
        if let timer = songTimer {
            timer.invalidate()
        }
        
        startSongTimer()
        
        progressSlider.hidden = false
    }
    
    private func updateNowPlayingWithItem(item: MPMediaItem) {
        playerController.nowPlayingItem = item
        updateView(item)
        
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
    
    private func startSongTimer() {
        songTimer = NSTimer.scheduledTimerWithTimeInterval(0.4,
            target: self,
            selector: Selector("updateProgress"),
            userInfo: nil,
            repeats: true)
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