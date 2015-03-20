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
    
    var sentScrobble = false
    
    private var pinchGesture: UIPinchGestureRecognizer!
    private var songTimer: NSTimer?
    
    @IBOutlet weak var artwork: UIImageView!
    @IBOutlet weak var songLabel: UILabel!
    @IBOutlet weak var shuffleButton: UIButton!
    @IBOutlet weak var repeatButton: UIButton!
    @IBOutlet weak var infoButton: UIButton!
    @IBOutlet weak var progressSlider: UISlider!
    @IBOutlet weak var tutorialView: UIView!
    @IBOutlet weak var progressOverlayView: UIView!
    @IBOutlet weak var progressOverlayViewLabel: UILabel!
    
    override init() {
        super.init(nibName: "NowPlayingViewController", bundle: nil)
        
        self.tabBarItem = UITabBarItem(title: "",
            image: UIImage(named: "headphones"),
            selectedImage: UIImage(named: "headphones"))
        self.tabBarItem.imageInsets = UIEdgeInsetsMake(6, 0, -6, 0)
    }
    
    init(song: Song, collection: MPMediaItemCollection) {
        super.init(nibName: "NowPlayingViewController", bundle: nil)
        
        self.song = song
        self.collection = collection
        
        configureWithSong()
        
        self.tabBarItem.imageInsets = UIEdgeInsetsMake(6, 0, -6, 0)
        
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "mediaLibraryDidChange",
            name: MPMediaLibraryDidChangeNotification,
            object: nil)
    }
    
    private func configureWithSong() {
        if let song = self.song {
            DataManager.manager.fetchItemForSong(song: song, completion: { (item) -> () in
                if let songItem = item {
                    self.item = songItem
                    self.playerController.setQueueWithItemCollection(self.collection)
                    self.playerController.nowPlayingItem = self.item
                    self.play()
                }
            })
            
        }
    }
    
    /**
    Handles updated the Datastore when iTunes library is updated
    */
    func mediaLibraryDidChange() {
//        DataManager.manager.syncSongs { (addedItems, error) -> () in
//            print("\n\nmedia library changed\n\n")
//        }
    }
    
    @IBAction func progressSliderTouchUpInside(sender: AnyObject) {
        UIView.animateWithDuration(0.3, animations: { () -> Void in
            self.progressOverlayView.alpha = 0.0
        })
    }
    
    @IBAction func progressSliderValueChanged(sender: AnyObject) {
        if let currentlyPlayingItem = item {
            UIView.animateWithDuration(0.3, animations: { () -> Void in
                self.progressOverlayView.alpha = 0.8
                
                
                var currentPlaybackTime = Double(self.progressSlider.value) * currentlyPlayingItem.playbackDuration
                self.playerController.currentPlaybackTime = currentPlaybackTime
                
                let min = floor(self.playerController.currentPlaybackTime/60)
                let sec = round(self.playerController.currentPlaybackTime - min * 60)
                self.progressOverlayViewLabel.text = NSString(format: "%2.f:%02.f", min, sec)
            }, completion: { (success) -> Void in
                
            })
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        self.screenName = "Now Playing"
        self.navigationItem.title = ""
        
        super.viewWillAppear(animated)
    }
    
    func dismiss() {
        self.navigationController?.popViewControllerAnimated(true)
    }

    func play() {
        self.playerController.play()
    }
    
    private func startSongTimer() {
        songTimer = NSTimer.scheduledTimerWithTimeInterval(0.4,
            target: self,
            selector: Selector("updateProgress"),
            userInfo: nil,
            repeats: true)
    }
    
    func updateProgress() {
        if let item = self.playerController.nowPlayingItem {
            progressSlider.value = Float(playerController.currentPlaybackTime) / Float(item.playbackDuration)
            
            if progressSlider.value > 0.51 {
                if SettingsManager.defaultManager.valueForMoreSetting(.LastFM) {
                    if !self.sentScrobble {
                        self.sentScrobble = true
                        LastFm.sharedInstance().sendScrobbledTrack(self.item.title, byArtist: self.item.artist, onAlbum: self.item.albumTitle, withDuration: self.item.playbackDuration, atTimestamp: NSDate().timeIntervalSince1970 - self.playerController.currentPlaybackTime, successHandler: { (responseData) -> Void in
                            LocalyticsSession.shared().tagEvent("Sent Scrobble")
                            print(responseData)
                            }, failureHandler: { (error) -> Void in
                                print(error)
                                //LocalyticsSession.shared().tagEvent("Failed Sent Scrobble")
                        })
                    }
                }
            }
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        CurrentQueueItems = self.collection
        songTimer?.invalidate()
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
        
        var nowPlayinglist = UIBarButtonItem(image: UIImage(named: "list"),
            style: .Plain,
            target: self,
            action: "showNowPlayingCollectionController")
        
        var addToPlaylist = UIBarButtonItem(image: UIImage(named: "add"),
            style: .Plain,
            target: self,
            action: "addToPlaylist")
        
        var search = UIBarButtonItem(image: UIImage(named: "search"),
            style: .Plain,
            target: self,
            action: "showSearch")
        
        self.navigationItem.rightBarButtonItems = [search, nowPlayinglist, addToPlaylist]
        
        progressSlider.setThumbImage(UIImage(named: "thumbImage"), forState: .Normal)
        progressSlider.setThumbImage(UIImage(named: "thumbImage"), forState: .Selected)
        
        LastFm.sharedInstance().apiKey = "d55a72556285ca314e7af8b0fb093e29"
        LastFm.sharedInstance().apiSecret = "affa81f90053b2114888298f3aeb27b9"

        if let session = NSUserDefaults.standardUserDefaults().objectForKey("LastFMSession") as? String {
            LastFm.sharedInstance().session = session
            if let username = NSUserDefaults.standardUserDefaults().objectForKey("LastFMUsername") as? String {
                LastFm.sharedInstance().username = username
            }
        }
        
        if let item = self.playerController.nowPlayingItem {
            self.item = item
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.updateNowPlaying()
                self.sendNowPlaying()
                
                var manager = DataManager.manager
                manager.datastore.songForSongName(self.item.title, artist: self.item.artist) { (song) -> () in
                    if let playingSong = song {
                        manager.datastore.updateSong(song: playingSong, completion: { () -> () in
                            
                        })
                    }
                }
            })
        }
    }
    
    func showSearch() {
        self.presentSearchOverlayController(SearchOverlayController(), blurredController: self)
    }
    
    func addToPlaylist() {
        
        if let nowPlayingItem = self.playerController.nowPlayingItem {
            
            let alertViewController = UIAlertController(title: "Create Playlist", message: "Please select what you want to create a playlist from.", preferredStyle: UIAlertControllerStyle.ActionSheet)
            
            let addAllArtistSongsAction = UIAlertAction(title: "All songs from Artist", style: .Default) { (action) -> Void in
                DataManager.manager.datastore.songForSongName(nowPlayingItem.title, artist: nowPlayingItem.artist, completion: { (song) -> () in
                    if let playingSong = song {
                        
                        let songsController = DataManager.manager.datastore.songsControllerWithSortKey("title", limit: nil, ascending: true, sectionNameKeyPath: nil)
                        songsController.fetchRequest.predicate = NSPredicate(format: "artist = %@", playingSong.artist)
                        
                        if songsController.performFetch(nil) {
                            if let songs = songsController.fetchedObjects {
                                let createPlaylistOverlay = CreatePlaylistOverlay(songs: songs)
                                self.presentModalOverlayController(createPlaylistOverlay, blurredController: self)
                            } else {
                                UIAlertView(title: "Error!",
                                    message: "Unable to find songs from that Artist.",
                                    delegate: self,
                                    cancelButtonTitle: "Ok").show()
                            }
                        }
                    }
                })
            }
            
            let addSongAction = UIAlertAction(title: "Currently playing song", style: .Default) { (action) -> Void in
                DataManager.manager.datastore.songForSongName(nowPlayingItem.title, artist: nowPlayingItem.artist, completion: { (song) -> () in
                    if let playingSong = song {
                        let createPlaylistOverlay = CreatePlaylistOverlay(songs: [playingSong])
                        self.presentModalOverlayController(createPlaylistOverlay, blurredController: self)
                    }
                })
            }
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel) { (action) -> Void in
                
            }
            
            alertViewController.addAction(addAllArtistSongsAction)
            alertViewController.addAction(addSongAction)
            alertViewController.addAction(cancelAction)
            
            self.presentViewController(alertViewController, animated: true, completion: nil)
            
        } else {
            UIAlertView(title: "Error!",
                message: "You must be playing a song to do that!",
                delegate: self,
                cancelButtonTitle: "Ok").show()
        }
    }
    
    func showNowPlayingCollectionController() {
        let nowPlayingCollectionController = NowPlayingCollectionController(collection: CurrentQueueItems)
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
            sentScrobble = false
            self.item = item
            var manager = DataManager.manager
            
            self.updateView()
            
            self.sendNowPlaying()
        }
        
        LocalyticsSession.shared().tagEvent("Played Song")
    }
    
    func sendNowPlaying() {
        
        if let username = NSUserDefaults.standardUserDefaults().objectForKey("LastFMUsername") as? String {
            if let password = NSUserDefaults.standardUserDefaults().objectForKey("LastFMPassword") as? String {
                LastFm.sharedInstance().getSessionForUser(username, password: password, successHandler: { (userData) -> Void in
                    LocalyticsSession.shared().tagEvent("Lastfm Login")
                    
                    LastFm.sharedInstance().sendNowPlayingTrack(self.item.title, byArtist: self.item.artist, onAlbum: self.item.albumTitle, withDuration: self.item.playbackDuration, successHandler: { (responseData) -> Void in
                        LocalyticsSession.shared().tagEvent("Sent NowPlaying Song")
                        print(responseData)
                        }, failureHandler: { (error) -> Void in
                            //LocalyticsSession.shared().tagEvent("Failed Sent NowPlaying Song")
                    })
                    
                    
                    }, failureHandler: { (error) -> Void in
                        LocalyticsSession.shared().tagEvent("Failed Lastfm Login")
                })
            }
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
        
        UIView.animateWithDuration(0.3, animations: { () -> Void in
            let noArtwork = UIImage(named: "nowPlayingDefault")!
            if let artwork = self.item.artwork {
                if let image = artwork.imageWithSize(CGSize(width:500, height:500)) {
                    self.artwork.image = image
                    CurrentAppBackgroundImage = image.applyDarkEffect()
                } else {
                    self.artwork.image = noArtwork
                    CurrentAppBackgroundImage = noArtwork.applyDarkEffect()
                }
            } else {
                self.artwork.image = noArtwork
                CurrentAppBackgroundImage = noArtwork.applyDarkEffect()
            }
            
            self.backgroundImageView.image = CurrentAppBackgroundImage
            
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
        })
        
        if let timer = songTimer {
            timer.invalidate()
        }
        
        startSongTimer()
        
        progressSlider.hidden = false
        
        if self.playerController.shuffleMode == .Off {
            shuffleButton.setTitleColor(MuzColor, forState: .Normal)
        } else {
            shuffleButton.setTitleColor(MuzBlueColor, forState: .Normal)
        }
        
        if self.playerController.repeatMode == .One {
            self.repeatButton.setTitleColor(MuzBlueColor, forState: .Normal)
        } else if self.playerController.repeatMode == .All {
            self.repeatButton.setTitleColor(MuzBlueColor, forState: .Normal)
            self.repeatButton.setTitle("Repeat All", forState: .Normal)
        } else {
            
            self.repeatButton.setTitleColor(MuzColor, forState: .Normal)
            self.repeatButton.setTitle("Repeat", forState: .Normal)
        }
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
    
    private func updateShuffle() {
        if playerController.shuffleMode == .Songs {
            playerController.shuffleMode = .Off
            shuffleButton.setTitleColor(MuzColor, forState: .Normal)
        } else {
            playerController.shuffleMode = .Songs
            shuffleButton.setTitleColor(MuzBlueColor, forState: .Normal)
        }
    }
    
    @IBAction func shuffleButtonPressed(sender: AnyObject) {
        self.updateShuffle()
    }
    
    @IBAction func repeatButtonPressed(sender: AnyObject) {
        self.updateRepeat()
    }
    
    func updateRepeat() {
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
}