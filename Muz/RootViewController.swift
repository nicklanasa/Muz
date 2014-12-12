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

class RootViewController: UIViewController {
    
    var backgroundImageView: UIImageView!
    
    override init() {
        super.init()
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewWillAppear(animated: Bool) {
        configureBackgroundImage()
    }
    
    override func viewDidLoad() {
        
        backgroundImageView = UIImageView(frame: UIScreen.mainScreen().bounds)
        backgroundImageView.contentMode = UIViewContentMode.ScaleAspectFill
        backgroundImageView.autoresizingMask = .FlexibleWidth
    
        configureBackgroundImage()
        
        view.insertSubview(backgroundImageView, atIndex: 0)
        
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "mediaLibraryDidChange",
            name: MPMediaLibraryDidChangeNotification,
            object: nil)
    }
    
    func configureBackgroundImage() {
        let delegate = UIApplication.sharedApplication().delegate as AppDelegate
        let image = delegate.currentAppBackgroundImage
        backgroundImageView.image = image.applyDarkEffect()
    }
    
    func mediaLibraryDidChange() {
        
    }
    
    func presentNowPlayViewControllerWithSongInfo(songInfo: NSDictionary) {
        if let song = MediaSession.sharedSession.dataManager.datastore.songForSongName(songInfo.objectForKey("title") as NSString) {
            if let delegate = UIApplication.sharedApplication().delegate as? AppDelegate {
                if let tabBarController = delegate.window?.rootViewController as? UITabBarController {
                    if let fromView = tabBarController.selectedViewController {
                        if let vcs = tabBarController.viewControllers {
                            if let navController = vcs[2] as? NavBarController {
                                if let nowPlayingViewController = navController.viewControllers.first as? NowPlayingViewController {
                                    let toView = nowPlayingViewController.view
                                    UIView.transitionFromView(fromView.view,
                                        toView: toView,
                                        duration: 0.2,
                                        options: .TransitionCrossDissolve,
                                        completion: { (success) -> Void in
                                            tabBarController.selectedIndex = 2
                                            nowPlayingViewController.playSong(song)
                                    })
                                }
                                
                            }
                        }
                    }
                }
            }
        }
    }
    
    func presentNowPlayViewControllerWithSongInfo(song: Song) {
        let songInfo = ["title" : song.title]
        presentNowPlayViewControllerWithSongInfo(songInfo)
    }
    
}
