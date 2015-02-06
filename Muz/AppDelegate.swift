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
let MuzFontNameRegular = "HelveticaNeue"
let MuzFontTutorial = "ShadowsIntoLight"
let MuzFont = UIFont(name: MuzFontName, size: 11)!
let MuzSettingFont = UIFont(name: MuzFontName, size: 21)!
let MuzTitleFont = UIFont(name: MuzFontNameMedium, size: 18)!
let MuzColor = UIColor.whiteColor()
let MuzBlueColor = UIColor(red:255/255, green: 184/255, blue: 60/255, alpha: 1.0)
let MuzGrayColor = UIColor(red:102/255, green: 102/255, blue: 102/255, alpha: 1.0)
var CurrentAppBackgroundImage = UIImage(named: "random.jpg")!

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    let noMusicOverlay = NoMusicOverlayController()
    
    let forumID = 279388

    private func muzWindow() -> UIWindow {
        
        let colorView = UIView()
        colorView.backgroundColor = UIColor.lightGrayColor().colorWithAlphaComponent(0.5)
        
        UINavigationBar.appearance().barTintColor = UIColor.blackColor()
        UITabBarItem.appearance().setTitleTextAttributes([NSFontAttributeName: MuzFont], forState: UIControlState.Normal)
        UIBarButtonItem.appearance().setTitleTextAttributes([NSForegroundColorAttributeName: UIColor.whiteColor()], forState: UIControlState.Normal)
        UIBarButtonItem.appearance().setBackButtonTitlePositionAdjustment(UIOffset(horizontal: -9999, vertical: 0), forBarMetrics: .Default)
        UITableViewCell.appearance().selectedBackgroundView = colorView
        UITableViewCell.appearance().backgroundColor = UIColor.clearColor()
        UITableView.appearance().sectionIndexColor = UIColor.lightGrayColor()
        UITableView.appearance().sectionIndexBackgroundColor = UIColor.clearColor()
        UITableView.appearance().separatorStyle = .None
        UITableView.appearance().separatorColor = UIColor.whiteColor()
        UITextField.appearance().textColor = UIColor.whiteColor()
        UISwitch.appearance().onTintColor = MuzBlueColor
        
        UVStyleSheet.instance().navigationBarBackgroundColor = UIColor.clearColor()
        UVStyleSheet.instance().navigationBarTintColor = UIColor.whiteColor()
        UVStyleSheet.instance().navigationBarTextColor = UIColor.whiteColor()
        UVStyleSheet.instance().tintColor = UIColor.blackColor()
        
        let mainScreen = UIScreen.mainScreen()
        let window = UIWindow(frame: mainScreen.bounds)
        
        let tabbar = TabBarController()
        let nav = NavBarController(rootViewController: ArtistsViewController())
        let navPlaylists = NavBarController(rootViewController: PlaylistsViewController())
        let navSongs = NavBarController(rootViewController: SongsViewController())
        let navMore = NavBarController(rootViewController: MoreViewController())
        let navNowPlaying = NavBarController(rootViewController: NowPlayingViewController())
        
        tabbar.setViewControllers([nav, navSongs, navNowPlaying, navPlaylists, navMore], animated: false)
        window.rootViewController = tabbar
        
        window.makeKeyAndVisible()
        
        return window
    }

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        LocalyticsSession.shared().integrateLocalytics("b25e652e274c5d45d413bc3-89bdf3a6-8e1f-11e4-a94d-009c5fda0a25",
            launchOptions: launchOptions)
        
        let types: UIUserNotificationType = (.Alert | .Badge | .Sound)
        let settings = UIUserNotificationSettings(forTypes: types, categories: nil)
        application.registerUserNotificationSettings(settings)
        application.registerForRemoteNotifications()
        
        if NSUserDefaults.standardUserDefaults().objectForKey("FirstTimer") == nil {
            SettingsManager.defaultManager.updateValueForMoreSetting(.ArtistInfo, value: NSNumber(bool: true))
            SettingsManager.defaultManager.updateValueForMoreSetting(.Lyrics, value: NSNumber(bool: true))
            NSUserDefaults.standardUserDefaults().setObject(NSNumber(bool: false), forKey: "FirstTimer")
        }
        
        self.window = muzWindow()
        
        var config = UVConfig(site: "nytekproductions.uservoice.com")
        config.forumId = forumID
        
        UserVoice.initialize(config)
        
        Appirater.setAppId("951709415")
        Appirater.setDaysUntilPrompt(1)
        Appirater.setUsesUntilPrompt(3)
        Appirater.appLaunched(true)
        
        if MediaSession.sharedSession.isMediaLibraryEmpty {
            addNoMusicOverlay()
        }
        
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
        Appirater.appEnteredForeground(true)
        
        if !MediaSession.sharedSession.isMediaLibraryEmpty {
            noMusicOverlay.view.removeFromSuperview()
            
        } else {
            if noMusicOverlay.view.superview == nil {
                addNoMusicOverlay()
            }
        }
        
        
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    private func addNoMusicOverlay() {
        self.window!.rootViewController?.addChildViewController(noMusicOverlay)
        noMusicOverlay.didMoveToParentViewController(self.window!.rootViewController)
        self.window!.rootViewController?.view.addSubview(noMusicOverlay.view)
    }
}

