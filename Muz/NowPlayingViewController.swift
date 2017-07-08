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
    
    fileprivate var pinchGesture: UIPinchGestureRecognizer!
    fileprivate var songTimer: Timer?
    
    @IBOutlet weak var artwork: UIImageView!
    @IBOutlet weak var songLabel: UILabel!
    @IBOutlet weak var shuffleButton: UIButton!
    @IBOutlet weak var repeatButton: UIButton!
    @IBOutlet weak var infoButton: UIButton!
    @IBOutlet weak var progressSlider: UISlider!
    @IBOutlet weak var tutorialView: UIView!
    @IBOutlet weak var progressOverlayView: UIView!
    @IBOutlet weak var progressOverlayViewLabel: UILabel!
    
    init() {
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
        
        NotificationCenter.default.addObserver(self,
            selector: #selector(NowPlayingViewController.mediaLibraryDidChange),
            name: NSNotification.Name.MPMediaLibraryDidChange,
            object: nil)
    }
    
    fileprivate func configureWithSong() {
        if let song = self.song {
            DataManager.manager.fetchItemForSong(song, completion: { (item) -> () in
                if let songItem = item, let collection = self.collection {
                    self.item = songItem
                    self.playerController.setQueue(with: collection)
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
    
    @IBAction func progressSliderTouchUpInside(_ sender: AnyObject) {
        UIView.animate(withDuration: 0.3, animations: { () -> Void in
            self.progressOverlayView.alpha = 0.0
        })
    }
    
    @IBAction func progressSliderValueChanged(_ sender: AnyObject) {
        if let currentlyPlayingItem = item {
            UIView.animate(withDuration: 0.3, animations: { () -> Void in
                self.progressOverlayView.alpha = 0.8
                
                
                let currentPlaybackTime = Double(self.progressSlider.value) * currentlyPlayingItem.playbackDuration
                self.playerController.currentPlaybackTime = currentPlaybackTime
                
                let min = floor(self.playerController.currentPlaybackTime/60)
                let sec = round(self.playerController.currentPlaybackTime - min * 60)
                self.progressOverlayViewLabel.text = String(format: "%2.f:%02.f", min, sec)
            }, completion: { (success) -> Void in
                
            })
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.screenName = "Now Playing"
        self.navigationItem.title = ""
        
        super.viewWillAppear(animated)
    }
    
    func dismiss() {
        self.navigationController?.popViewController(animated: true)
    }

    func play() {
        self.playerController.play()
    }
    
    fileprivate func startSongTimer() {
        songTimer = Timer.scheduledTimer(timeInterval: 0.4,
            target: self,
            selector: #selector(NowPlayingViewController.updateProgress),
            userInfo: nil,
            repeats: true)
    }
    
    func updateProgress() {
        if let item = self.playerController.nowPlayingItem {
            progressSlider.value = Float(playerController.currentPlaybackTime) / Float(item.playbackDuration)
            
            if progressSlider.value > 0.51 {
                if SettingsManager.defaultManager.valueForMoreSetting(.lastFM) {
                    if !self.sentScrobble {
                        self.sentScrobble = true
                        LastFm.sharedInstance().sendScrobbledTrack(self.item.title, byArtist: self.item.artist, onAlbum: self.item.albumTitle, withDuration: self.item.playbackDuration, atTimestamp: Date().timeIntervalSince1970 - self.playerController.currentPlaybackTime, successHandler: { (responseData) -> Void in
                            print(responseData, terminator: "")
                            }, failureHandler: { (error) -> Void in
                                print(error, terminator: "")
                                //LocalyticsSession.shared().tagEvent("Failed Sent Scrobble")
                        })
                    }
                }
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        CurrentQueueItems = self.collection
        songTimer?.invalidate()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let swipeLeftGesture = UISwipeGestureRecognizer(target: self, action: #selector(NowPlayingViewController.nextSong))
        swipeLeftGesture.direction = .left
        view.addGestureRecognizer(swipeLeftGesture)
        
        let swipeRightGesture = UISwipeGestureRecognizer(target: self, action: #selector(NowPlayingViewController.previousSong))
        swipeRightGesture.direction = .right
        view.addGestureRecognizer(swipeRightGesture)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(NowPlayingViewController.playPause))
        tapGesture.numberOfTapsRequired = 1
        artwork.addGestureRecognizer(tapGesture)
        
        NotificationCenter.default.addObserver(self,
            selector: #selector(NowPlayingViewController.playPause),
            name: NSNotification.Name.UIApplicationWillTerminate,
            object: nil)
        
        NotificationCenter.default.addObserver(self,
            selector: #selector(NowPlayingViewController.applicationDidEnterBackground),
            name: NSNotification.Name.UIApplicationDidEnterBackground,
            object: nil)
        
        NotificationCenter.default.addObserver(self,
            selector: #selector(NowPlayingViewController.playerControllerDidNowPlayingItemDidChange),
            name: NSNotification.Name.MPMusicPlayerControllerNowPlayingItemDidChange,
            object: nil)
        
        playerController.beginGeneratingPlaybackNotifications()
        
        let nowPlayinglist = UIBarButtonItem(image: UIImage(named: "list"),
            style: .plain,
            target: self,
            action: #selector(NowPlayingViewController.showNowPlayingCollectionController))
        
        let addToPlaylist = UIBarButtonItem(image: UIImage(named: "add"),
            style: .plain,
            target: self,
            action: #selector(NowPlayingViewController.addToPlaylist))
        
        let search = UIBarButtonItem(image: UIImage(named: "search"),
            style: .plain,
            target: self,
            action: #selector(NowPlayingViewController.showSearch))
        
        self.navigationItem.rightBarButtonItems = [search, nowPlayinglist, addToPlaylist]
        
        progressSlider.setThumbImage(UIImage(named: "thumbImage"), for: UIControlState())
        progressSlider.setThumbImage(UIImage(named: "thumbImage"), for: .selected)
        
        if let item = self.playerController.nowPlayingItem {
            self.item = item
            
            DispatchQueue.main.async(execute: { () -> Void in
                self.updateNowPlaying()
                self.sendNowPlaying()
                
                let manager = DataManager.manager
                
                if let title = self.item.title, let artist = self.item.artist {
                    manager.datastore.songForSongName(title, artist: artist) { (song) -> () in
                        if let playingSong = song {
                            manager.datastore.updateSong(song: playingSong, completion: { () -> () in
                                
                            })
                        }
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
            
            let alertViewController = UIAlertController(title: "Create Playlist", message: "Please select what you want to create a playlist from.", preferredStyle: UIAlertControllerStyle.actionSheet)
            
            let addAllArtistSongsAction = UIAlertAction(title: "All songs from Artist", style: .default) { (action) -> Void in
                if let title = self.item.title, let artist = self.item.artist {
                    DataManager.manager.datastore.songForSongName(title, artist: artist, completion: { (song) -> () in
                        if let playingSong = song {
                            
                            let songsController = DataManager.manager.datastore.songsControllerWithSortKey("title", limit: nil, ascending: true, sectionNameKeyPath: nil)
                            songsController.fetchRequest.predicate = NSPredicate(format: "artist = %@", playingSong.artist)
                            
                            do {
                                try songsController.performFetch()
                                if let songs = songsController.fetchedObjects {
                                    let createPlaylistOverlay = CreatePlaylistOverlay(songs: songs)
                                    self.presentModalOverlayController(createPlaylistOverlay, blurredController: self)
                                } else {
                                    UIAlertView(title: "Error!",
                                        message: "Unable to find songs from that Artist.",
                                        delegate: self,
                                        cancelButtonTitle: "Ok").show()
                                }
                            } catch _ {
                            }
                        }
                    })
                }
            }
            
            let addSongAction = UIAlertAction(title: "Currently playing song", style: .default) { (action) -> Void in
                if let title = nowPlayingItem.title, let artist = nowPlayingItem.artist {
                    DataManager.manager.datastore.songForSongName(title, artist: artist, completion: { (song) -> () in
                        if let playingSong = song {
                            let createPlaylistOverlay = CreatePlaylistOverlay(songs: [playingSong])
                            self.presentModalOverlayController(createPlaylistOverlay, blurredController: self)
                        }
                    })
                }
            }
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (action) -> Void in
                
            }
            
            alertViewController.addAction(addAllArtistSongsAction)
            alertViewController.addAction(addSongAction)
            alertViewController.addAction(cancelAction)
            
            if let popoverController = alertViewController.popoverPresentationController {
                popoverController.barButtonItem = self.navigationItem.rightBarButtonItem
            }
            
            self.present(alertViewController, animated: true, completion: nil)
            
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
        if self.playerController.playbackState == .playing {
            self.playerController.pause()
        } else {
            self.playerController.play()
        }
    }
    
    func playerControllerDidNowPlayingItemDidChange() {
        if let item = self.playerController.nowPlayingItem {
            sentScrobble = false
            self.item = item
            self.updateView()
        }
    }
    
    func nextSong() {
        if self.playerController.repeatMode == .one {
            self.updateNowPlaying()
            self.playerController.stop()
            self.playerController.play()
        } else {
            
            let artworkCenter = self.artwork.center
            let songLabelCenter = self.songLabel.center
            
            UIView.animate(withDuration: 0.15, animations: { () -> Void in
                self.songLabel.frame = CGRect(x: 0 - self.songLabel.frame.size.width,
                    y: self.songLabel.frame.origin.y, width: self.songLabel.frame.size.width, height: self.songLabel.frame.size.height)
                self.artwork.frame = CGRect(x: 0 - self.artwork.frame.size.width,
                    y: self.artwork.frame.origin.y, width: self.artwork.frame.size.width, height: self.artwork.frame.size.height)
                
                self.songLabel.alpha = 0.0
                self.artwork.alpha = 0.0
                
                self.playerController.skipToNextItem()
                
                }, completion: { (success) -> Void in
                    
                    self.songLabel.frame = CGRect(x: UIScreen.main.bounds.width + self.songLabel.frame.size.width,
                        y: self.songLabel.frame.origin.y, width: self.songLabel.frame.size.width, height: self.songLabel.frame.size.height)
                    self.artwork.frame = CGRect(x: UIScreen.main.bounds.width + self.artwork.frame.size.width,
                        y: self.artwork.frame.origin.y, width: self.artwork.frame.size.width, height: self.artwork.frame.size.height)
                    
                    UIView.animate(withDuration: 0.15, animations: { () -> Void in
                        
                        self.songLabel.alpha = 1.0
                        self.artwork.alpha = 1.0
                        
                        self.songLabel.center = songLabelCenter
                        self.artwork.center = artworkCenter
                    })
            })
        }
    }
    
    func previousSong() {
        if playerController.repeatMode == .one {
            
            self.updateNowPlaying()
            
            self.playerController.stop()
            self.playerController.play()
        } else {
            let artworkCenter = self.artwork.center
            let songLabelCenter = self.songLabel.center
            
            UIView.animate(withDuration: 0.15, animations: { () -> Void in
                self.songLabel.frame = CGRect(x: UIScreen.main.bounds.width +  self.songLabel.frame.size.width,
                    y: self.songLabel.frame.origin.y, width: self.songLabel.frame.size.width, height: self.songLabel.frame.size.height)
                self.artwork.frame = CGRect(x: UIScreen.main.bounds.width +  self.artwork.frame.size.width,
                    y: self.artwork.frame.origin.y, width: self.artwork.frame.size.width, height: self.artwork.frame.size.height)
                
                self.songLabel.alpha = 0.0
                self.artwork.alpha = 0.0
                
                self.playerController.skipToPreviousItem()
                
                }, completion: { (success) -> Void in
                    
                    self.songLabel.frame = CGRect(x: 0 - self.songLabel.frame.size.width,
                        y: self.songLabel.frame.origin.y, width: self.songLabel.frame.size.width, height: self.songLabel.frame.size.height)
                    self.artwork.frame = CGRect(x: 0 - self.artwork.frame.size.width,
                        y: self.artwork.frame.origin.y, width: self.artwork.frame.size.width, height: self.artwork.frame.size.height)
                    
                    UIView.animate(withDuration: 0.15, animations: { () -> Void in
                        
                        self.songLabel.alpha = 1.0
                        self.artwork.alpha = 1.0
                        
                        self.songLabel.center = songLabelCenter
                        self.artwork.center = artworkCenter
                    })
            })
        }
    }

    // MARK: Updating
    
    func showInfoController(_ gesture: UIPinchGestureRecognizer?) {
        UIView.animate(withDuration: 0.3, animations: { () -> Void in
            UIView.animate(withDuration: 0.3, animations: { () -> Void in
                self.hideNowPlayingViews()
            })
        })
    }
    
    func hideInfoController(_ gesture: UIPinchGestureRecognizer?) {
        UIView.animate(withDuration: 0.3, animations: { () -> Void in
            self.showNowPlayingViews()
        })
    }
    
    fileprivate func hideNowPlayingViews() {
        UIView.animate(withDuration: 0.3, animations: { () -> Void in
            self.artwork.alpha = 0.0
            self.songLabel.alpha = 0.0
            self.progressSlider.alpha = 0.0
            self.shuffleButton.alpha = 0.0
            self.repeatButton.alpha = 0.0
            self.infoButton.alpha = 0.0
        })
    }
    
    fileprivate func showNowPlayingViews() {
        UIView.animate(withDuration: 0.3, animations: { () -> Void in
            self.artwork.alpha = 1.0
            self.songLabel.alpha = 1.0
            self.progressSlider.alpha = 1.0
            
            self.shuffleButton.alpha = 1.0
            self.repeatButton.alpha = 1.0
            self.infoButton.alpha = 1.0
        })
    }
    
    fileprivate func updateView() {
        
        showNowPlayingViews()
        
        UIView.animate(withDuration: 0.3, animations: { () -> Void in
            let noArtwork = UIImage(named: "nowPlayingDefault")!
            if let artwork = self.item.artwork {
                if let image = artwork.image(at: CGSize(width:500, height:500)) {
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
            
            if let title = self.item.title, let artist = self.item.artist, let albumTitle = self.item.albumTitle {
                let songInfo = NSString(format: "%@\n%@\n%@", title, artist, albumTitle)
                let attributedSongInfo = NSMutableAttributedString(string: songInfo as String)
                let songFont = UIFont(name: MuzFontName, size: 35)!
                let artistFont = UIFont(name: MuzFontNameRegular, size: 18)!
                attributedSongInfo.addAttribute(NSFontAttributeName,
                    value: songFont,
                    range: NSMakeRange(0, title.characters.count))
                attributedSongInfo.addAttribute(NSFontAttributeName,
                    value: artistFont,
                    range: NSMakeRange(title.characters.count,
                        artist.characters.count + 1))
                self.songLabel.attributedText = attributedSongInfo
            }
        })
        
        if let timer = songTimer {
            timer.invalidate()
        }
        
        startSongTimer()
        
        progressSlider.isHidden = false
        
        if self.playerController.shuffleMode == .off {
            shuffleButton.setTitleColor(MuzColor, for: UIControlState())
        } else {
            shuffleButton.setTitleColor(MuzBlueColor, for: UIControlState())
        }
        
        if self.playerController.repeatMode == .one {
            self.repeatButton.setTitleColor(MuzBlueColor, for: UIControlState())
        } else if self.playerController.repeatMode == .all {
            self.repeatButton.setTitleColor(MuzBlueColor, for: UIControlState())
            self.repeatButton.setTitle("Repeat All", for: UIControlState())
        } else {
            
            self.repeatButton.setTitleColor(MuzColor, for: UIControlState())
            self.repeatButton.setTitle("Repeat", for: UIControlState())
        }
    }
    
    fileprivate func updateNowPlaying() {
        
        playerController.nowPlayingItem = self.item
        
        self.updateView()
        
        if UserDefaults.standard.object(forKey: "Tutorial") == nil {
            tutorialView.alpha = 0.85
            
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(NowPlayingViewController.dismissTutorial))
            tapGesture.numberOfTapsRequired = 1
            tutorialView.addGestureRecognizer(tapGesture)
            UserDefaults.standard.set(NSNumber(value: false as Bool), forKey: "Tutorial")
        } else {
            tutorialView.alpha = 0.0
        }
        
        WKNotificationCenter.defaultCenter(withGroupIndentifier: "group.muz").postNotificationObject(["nowPlayingArtwork": self.artwork.image!],
            identifier: "nowPlayingArtwork")
    }
    
    func dismissTutorial() {
        UIView.animate(withDuration: 0.3, animations: { () -> Void in
            self.tutorialView.alpha = 0.0
            self.tutorialView.removeFromSuperview()
        })
    }
    
    // MARK: IBAction
    
    @IBAction func infoButtonPressed(_ sender: AnyObject) {
        if let _ = self.item {
            DispatchQueue.main.async(execute: { () -> Void in
                let controller = NowPlayingInfoViewController(item: self.item)
                self.navigationController?.pushViewController(controller, animated: true)
            })
        } else {
            UIAlertView(title: "Error!",
                message: "You must be listening to a track to see info.",
                delegate: self,
                cancelButtonTitle: "Ok").show()
        }
    }
    
    fileprivate func updateShuffle() {
        if playerController.shuffleMode == .songs {
            playerController.shuffleMode = .off
            shuffleButton.setTitleColor(MuzColor, for: UIControlState())
        } else {
            playerController.shuffleMode = .songs
            shuffleButton.setTitleColor(MuzBlueColor, for: UIControlState())
        }
    }
    
    @IBAction func shuffleButtonPressed(_ sender: AnyObject) {
        self.updateShuffle()
    }
    
    @IBAction func repeatButtonPressed(_ sender: AnyObject) {
        self.updateRepeat()
    }
    
    func updateRepeat() {
        UIView.animate(withDuration: 0.3, animations: { () -> Void in
            if self.playerController.repeatMode == .one {
                self.playerController.repeatMode = .none
                self.repeatButton.setTitleColor(MuzColor, for: UIControlState())
                self.repeatButton.setTitle("Repeat", for: UIControlState())
            } else if self.playerController.repeatMode == .all {
                self.playerController.repeatMode = .one
                self.repeatButton.setTitleColor(MuzBlueColor, for: UIControlState())
                self.repeatButton.setTitle("Repeat", for: UIControlState())
            } else {
                self.playerController.repeatMode = .all
                self.repeatButton.setTitleColor(MuzBlueColor, for: UIControlState())
                self.repeatButton.setTitle("Repeat All", for: UIControlState())
            }
        })

    }
    
    func nowPlayingCollectionController(_ controller: NowPlayingCollectionController,
        didSelectItem item: MPMediaItem) {
        playerController.stop()
        playerController.nowPlayingItem = item
        playerController.play()
    }
}
