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
    
    var screenName: NSString! {
        didSet {
            self.navigationItem.title = screenName
        }
    }
    
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
        
        if NSUserDefaults.standardUserDefaults().objectForKey("SyncLibrary") == nil {
            self.presentModalOverlayController(SyncOverlayController(), blurredController: self)
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        LocalyticsSession.shared().tagScreen(screenName)
    }
    
    override func viewDidLoad() {
        self.backgroundImageView = UIImageView(frame: UIScreen.mainScreen().bounds)
        self.backgroundImageView.contentMode = UIViewContentMode.ScaleToFill
        self.backgroundImageView.autoresizingMask = .FlexibleWidth
        
        self.configureBackgroundImage()
        
        if self.backgroundImageView.superview == nil {
            self.view.insertSubview(self.backgroundImageView, atIndex: 0)
        }
        
        self.searchDisplayController?.searchResultsTableView.backgroundColor = UIColor.clearColor()
        self.searchDisplayController?.searchResultsTableView.separatorStyle = .None
        
        self.searchDisplayController?.searchResultsTableView.autoresizingMask = .FlexibleWidth | .FlexibleHeight
    }
    
    func configureBackgroundImage() {
        self.backgroundImageView.image = CurrentAppBackgroundImage.applyDarkEffect()
    }
    
    /**
    TODO: Change this to use Song.
    Presents the NowPlaying ViewController with the selected item.
    
    :param: item The MPMediaItem you want to play.
    */
    func presentNowPlayViewControllerWithItem(item: MPMediaItem) {
        let window = UIApplication.sharedApplication().keyWindow
        if let tabBarController = window!.rootViewController as? UITabBarController {
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
                                    nowPlayingViewController.playItem(item)
                            })
                        }
                        
                    }
                }
            }
        }
    }
    
    func presentNowPlayViewController(song: Song, collection: MPMediaItemCollection) {
        let window = UIApplication.sharedApplication().keyWindow
        if let tabBarController = window!.rootViewController as? UITabBarController {
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
                                    nowPlayingViewController.playSong(song, collection: collection)
                            })
                        }
                        
                    }
                }
            }
        }
    }
    
    /**
    TODO: Change this to use Song.
    Presents the NowPlaying ViewController with the selected item.
    
    :param: item The MPMediaItem you want to play.
    :param: collection The collection you wish to queue up.
    */
    func presentNowPlayViewControllerWithItem(item: MPMediaItem, collection: MPMediaItemCollection) {
        let window = UIApplication.sharedApplication().keyWindow
        if let tabBarController = window!.rootViewController as? UITabBarController {
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
                                    nowPlayingViewController.playItem(item, collection: collection)
                            })
                        }
                        
                    }
                }
            }
        }
    }
    
    /**
    Presents a model overlay ViewController with the given controller and blurredController to blur in the background.
    
    :param: controller        The controller you wish you present.
    :param: blurredController The controller you wish to blur in the background.
    */
    func presentModalOverlayController(controller: OverlayController, blurredController: UIViewController) {

        UIGraphicsBeginImageContext(blurredController.view.bounds.size)
        self.view.layer.renderInContext(UIGraphicsGetCurrentContext())
        var image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        controller.screenShot = image
        
        let nav = NavBarController(rootViewController: controller)
        presentViewController(nav, animated: true, completion: nil)
    }
    
    /**
    Present the CreatePlaylist Controller with the given controller.
    
    :param: controller The controller you wish to blur in the background.
    */
    func presentCreatePlaylistFromController(controller: OverlayController) {
        
        UIGraphicsBeginImageContext(self.view.bounds.size)
        self.view.layer.renderInContext(UIGraphicsGetCurrentContext())
        var image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        self.addChildViewController(controller)
        controller.didMoveToParentViewController(self)
        
        controller.screenShot = image
        
        self.view.addSubview(controller.view)
        
        controller.view.alpha = 0.0
        controller.view.frame = CGRectOffset(controller.view.frame, 0, UIScreen.mainScreen().bounds.size.height)
        
        UIView.animateWithDuration(0.4, animations: { () -> Void in
            controller.view.frame = CGRectOffset(controller.view.frame, 0, -400.0)
            controller.view.alpha = 1.0
        })
    }
    
    override func didRotateFromInterfaceOrientation(fromInterfaceOrientation: UIInterfaceOrientation) {
        if fromInterfaceOrientation == .LandscapeLeft || fromInterfaceOrientation == .LandscapeRight {
            println(UIScreen.mainScreen().bounds.size)
            self.backgroundImageView.contentMode = UIViewContentMode.ScaleToFill
            self.backgroundImageView.image = backgroundImageView.image
        } else {
            println(UIScreen.mainScreen().bounds.size)
            self.backgroundImageView.contentMode = UIViewContentMode.ScaleAspectFill
            self.backgroundImageView.image = backgroundImageView.image
        }
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return false
    }
}
