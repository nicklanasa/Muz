//
//  RootViewController.swift
//  Muz
//
//  Created by Nick Lanasa on 12/9/14.
//  Copyright (c) 2014 Nytek Productions. All rights reserved.
//

import Foundation
import UIKit
import MediaPlayer

class RootViewController: UIViewController, SearchOverlayControllerDelegate {
    
    var backgroundImageView: UIImageView!
    
    var screenName: String! {
        didSet {
            self.navigationItem.title = screenName
        }
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        configureBackgroundImage()
        
        if UserDefaults.standard.object(forKey: "SyncLibrary") == nil {
            self.presentModalOverlayController(SyncOverlayController(), blurredController: self)
        }
        
        NotificationCenter.default.addObserver(self,
            selector: #selector(RootViewController.sendNowPlaying),
            name: NSNotification.Name.MPMusicPlayerControllerNowPlayingItemDidChange,
            object: nil)
    }
    
    func sendNowPlaying() {
        if let item = MPMusicPlayerController.iPodMusicPlayer().nowPlayingItem {
            if let username = UserDefaults.standard.object(forKey: "LastFMUsername") as? String {
                if let password = UserDefaults.standard.object(forKey: "LastFMPassword") as? String {
                    LastFm.sharedInstance().getSessionForUser(username, password: password, successHandler: { (userData) -> Void in
                        
                        LastFm.sharedInstance().sendNowPlayingTrack(item.title, byArtist: item.artist, onAlbum: item.albumTitle, withDuration: item.playbackDuration, successHandler: { (responseData) -> Void in
                            print(responseData, terminator: "")
                            }, failureHandler: { (error) -> Void in
                                //LocalyticsSession.shared().tagEvent("Failed Sent NowPlaying Song")
                        })
                        
                        
                        }, failureHandler: { (error) -> Void in
                    })
                }
            }
        }
    }
    
    override func viewDidLoad() {
        if backgroundImageView == nil {
            self.backgroundImageView = UIImageView(frame: UIScreen.main.bounds)
            self.backgroundImageView.contentMode = UIViewContentMode.scaleToFill
            self.backgroundImageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            self.view.insertSubview(self.backgroundImageView, at: 0)
        }
        
        self.configureBackgroundImage()

        self.searchDisplayController?.searchResultsTableView.backgroundColor = UIColor.clear
        self.searchDisplayController?.searchResultsTableView.separatorStyle = .none
        
        self.searchDisplayController?.searchResultsTableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }
    
    func configureBackgroundImage() {
        self.backgroundImageView.image = CurrentAppBackgroundImage
    }
    
    /**
    TODO: Change this to use Song.
    Presents the NowPlaying ViewController with the selected item.
    
    - parameter item: The MPMediaItem you want to play.
    */
    func presentNowPlayViewController() {
        let nowPlayingViewController = NowPlayingViewController()
        self.navigationController?.pushViewController(nowPlayingViewController, animated: true)
    }
    
    func presentNowPlayViewController(_ song: Song, collection: MPMediaItemCollection) {
        DispatchQueue.main.async(execute: { () -> Void in
            let nowPlayingViewController = NowPlayingViewController(song: song, collection: collection)
            self.navigationController?.pushViewController(nowPlayingViewController, animated: true)
        })
    }

    /**
    Presents a model overlay ViewController with the given controller and blurredController to blur in the background.
    
    - parameter controller:        The controller you wish you present.
    - parameter blurredController: The controller you wish to blur in the background.
    */
    func presentModalOverlayController(_ controller: OverlayController, blurredController: UIViewController) {

        UIGraphicsBeginImageContext(blurredController.view.bounds.size)
        self.view.layer.render(in: UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        controller.screenShot = image
        
        let nav = NavBarController(rootViewController: controller)
        present(nav, animated: true, completion: nil)
    }
    
    func presentSearchOverlayController(_ controller: SearchOverlayController, blurredController: UIViewController) {
        UIGraphicsBeginImageContext(blurredController.view.bounds.size)
        self.view.layer.render(in: UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        controller.screenShot = image
        
        //let nav = NavBarController(rootViewController: controller)
        
        controller.delegate = self
        
        present(controller, animated: true, completion: nil)
    }
    
    /**
    Present the CreatePlaylist Controller with the given controller.
    
    - parameter controller: The controller you wish to blur in the background.
    */
    func presentCreatePlaylistFromController(_ controller: OverlayController) {
        
        UIGraphicsBeginImageContext(self.view.bounds.size)
        self.view.layer.render(in: UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        self.addChildViewController(controller)
        controller.didMove(toParentViewController: self)
        
        controller.screenShot = image
        
        self.view.addSubview(controller.view)
        
        controller.view.alpha = 0.0
        controller.view.frame = controller.view.frame.offsetBy(dx: 0, dy: UIScreen.main.bounds.size.height)
        
        UIView.animate(withDuration: 0.4, animations: { () -> Void in
            controller.view.frame = controller.view.frame.offsetBy(dx: 0, dy: -400.0)
            controller.view.alpha = 1.0
        })
    }
    
    func searchOverlayController(_ controller: SearchOverlayController, didTapArtist artist: Artist) {
        DispatchQueue.main.async(execute: { () -> Void in
            let artistAlbums = ArtistAlbumsViewController(artist: artist)
            self.navigationController?.pushViewController(artistAlbums, animated: true)
        })
    }
    
    func searchOverlayController(_ controller: SearchOverlayController, didTapSong song: Song) {
        MediaSession.sharedSession.fetchArtistCollectionForArtist(artist: song.artist) { (collection) -> () in
            if collection != nil {
                self.presentNowPlayViewController(song, collection: collection!)
            } else {
                UIAlertView(title: "Error!",
                    message: "Unable to get collection!",
                    delegate: self,
                    cancelButtonTitle: "Ok").show()
            }
        }
    }
}
