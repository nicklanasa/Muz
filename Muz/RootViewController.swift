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
    }
    
    override func viewDidAppear(animated: Bool) {
        LocalyticsSession.shared().tagScreen(screenName)
    }
    
    override func viewDidLoad() {
        
        backgroundImageView = UIImageView(frame: UIScreen.mainScreen().bounds)
        backgroundImageView.contentMode = UIViewContentMode.ScaleToFill
        backgroundImageView.autoresizingMask = .FlexibleWidth
        
        configureBackgroundImage()
        
        if backgroundImageView.superview == nil {
            view.insertSubview(backgroundImageView, atIndex: 0)
        }
        
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "mediaLibraryDidChange",
            name: MPMediaLibraryDidChangeNotification,
            object: nil)
        
        searchDisplayController?.searchResultsTableView.backgroundColor = UIColor.clearColor()
        searchDisplayController?.searchResultsTableView.separatorStyle = .None
        
        searchDisplayController?.searchResultsTableView.autoresizingMask = .FlexibleWidth | .FlexibleHeight
    }
    
    func configureBackgroundImage() {
        backgroundImageView.image = CurrentAppBackgroundImage.applyDarkEffect()
    }
    
    func mediaLibraryDidChange() {
       
    }
    
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
        } else if let splitViewController = window!.rootViewController as? UISplitViewController {
            if let navController = splitViewController.viewControllers[1] as? NavBarController {
                if let nowPlayingViewController = navController.viewControllers.first as? NowPlayingViewController {
                    nowPlayingViewController.playItem(item)
                }
            }
        }    }
    
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
        } else if let splitViewController = window!.rootViewController as? UISplitViewController {
            if let navController = splitViewController.viewControllers[1] as? NavBarController {
                if let nowPlayingViewController = navController.viewControllers.first as? NowPlayingViewController {
                    nowPlayingViewController.playItem(item)
                }
            }
        }
        
    }
    
    func presentModalOverlayController(controller: OverlayController, blurredController: UIViewController) {

        UIGraphicsBeginImageContext(blurredController.view.bounds.size)
        self.view.layer.renderInContext(UIGraphicsGetCurrentContext())
        var image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        controller.screenShot = image
        
        let nav = NavBarController(rootViewController: controller)
        presentViewController(nav, animated: true, completion: nil)
    }
    
    func presentCreatePlaylistFromController(controller: OverlayController) {
        
        UIGraphicsBeginImageContext(self.view.bounds.size)
        self.view.layer.renderInContext(UIGraphicsGetCurrentContext())
        var image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        self.addChildViewController(controller)
        controller.didMoveToParentViewController(self)
        
        controller.screenShot = image
        
        view.addSubview(controller.view)
        
        controller.view.alpha = 0.0
        controller.view.frame = CGRectOffset(controller.view.frame, 0, UIScreen.mainScreen().bounds.size.height)
        
        UIView.animateWithDuration(0.4, animations: { () -> Void in
            controller.view.frame = CGRectOffset(controller.view.frame, 0, -400.0)
            controller.view.alpha = 1.0
        })
    }
    
    override func didRotateFromInterfaceOrientation(fromInterfaceOrientation: UIInterfaceOrientation) {
        //self.backgroundImageView.frame = UIScreen.mainScreen().bounds
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
