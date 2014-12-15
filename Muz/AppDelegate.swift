//
//  AppDelegate.swift
//  Muz
//
//  Created by Nick Lanasa on 12/8/14.
//  Copyright (c) 2014 Nytek Productions. All rights reserved.
//

import UIKit

let MuzFontName = "HelveticaNeue-Thin"
let MuzFontNameMedium = "HelveticaNeue-Medium"
let MuzFont = UIFont(name: MuzFontName, size: 11)!
let MuzTitleFont = UIFont(name: MuzFontNameMedium, size: 18)!
//let MuzColor = UIColor(red:55/255, green: 216/255, blue: 200/255, alpha: 1.0)
let MuzColor = UIColor.whiteColor()

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var currentAppBackgroundImage: UIImage = UIImage(named: "random.jpg")!

    private func muzWindow() -> UIWindow {
        
        let colorView = UIView()
        colorView.backgroundColor = UIColor.lightGrayColor().colorWithAlphaComponent(0.5)
        
        UITabBarItem.appearance().setTitleTextAttributes([NSFontAttributeName: MuzFont], forState: UIControlState.Normal)
        UIBarButtonItem.appearance().setTitleTextAttributes([NSForegroundColorAttributeName: UIColor.whiteColor()], forState: UIControlState.Normal)
        UITableViewCell.appearance().selectedBackgroundView = colorView
        UITableViewCell.appearance().backgroundColor = UIColor.clearColor()
        UIBarButtonItem.appearance().setBackButtonTitlePositionAdjustment(UIOffsetMake(-100, 0), forBarMetrics: UIBarMetrics.Default)
        UIBarButtonItem.appearance().setBackButtonBackgroundImage(UIImage(named: "back"), forState: .Normal, barMetrics: .Default)

        
        let mainScreen = UIScreen.mainScreen()
        let window = UIWindow(frame: mainScreen.bounds)
        
        let tabbar = TabBarController()
        let nav = NavBarController(rootViewController: ArtistsViewController())
        let navLoved = NavBarController(rootViewController: LovedViewController())
        let navSongs = NavBarController(rootViewController: SongsViewController())
        let navMore = NavBarController(rootViewController: MoreViewController())
        let navNowPlaying = NavBarController(rootViewController: NowPlayingViewController())
        tabbar.setViewControllers([nav, navSongs, navNowPlaying, navLoved, navMore], animated: false)
        window.rootViewController = tabbar
        window.makeKeyAndVisible()
        
        return window
    }

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        self.window = muzWindow()
        
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        
        MediaSession.sharedSession.openSessionWithUpdateBlock { (percentage, error, song) -> () in
            println("iPod Library Sync percentage \(percentage * 100)%")
        }
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

