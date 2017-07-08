//
//  AppDelegate.swift
//  Muz
//
//  Created by Nick Lanasa on 12/8/14.
//  Copyright (c) 2014 Nytek Productions. All rights reserved.
//

import UIKit
import MediaPlayer

let MuzFontName = "HelveticaNeue-Thin"
let MuzFontNameMedium = "HelveticaNeue-Medium"
let MuzFontNameRegular = "HelveticaNeue"
let MuzFontTutorial = "ShadowsIntoLight"
let MuzFont = UIFont(name: MuzFontName, size: 11)!
let MuzSettingFont = UIFont(name: MuzFontName, size: 21)!
let MuzTitleFont = UIFont(name: MuzFontNameMedium, size: 18)!
let MuzColor = UIColor.white
let MuzBlueColor = UIColor(red:255/255, green: 184/255, blue: 60/255, alpha: 1.0)
let MuzGrayColor = UIColor(red:102/255, green: 102/255, blue: 102/255, alpha: 1.0)

var CurrentNowPlayingArtwork: UIImage = UIImage(named: "nowPlayingDefault")!
var CurrentAppBackgroundImage = UIImage(named: "nowPlayingDefault")?.applyDarkEffect()!

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UIAlertViewDelegate {

    var window: UIWindow?
    var hud: MBProgressHUD!
    
    let forumID = 279388

    fileprivate func muzWindow() -> UIWindow {
        
        let colorView = UIView()
        colorView.backgroundColor = UIColor.lightGray.withAlphaComponent(0.5)
        
        UINavigationBar.appearance().barTintColor = UIColor.black
        UITabBarItem.appearance().setTitleTextAttributes([NSFontAttributeName: MuzFont], for: UIControlState())
        UIBarButtonItem.appearance().setTitleTextAttributes([NSForegroundColorAttributeName: UIColor.white], for: UIControlState())
        UIBarButtonItem.appearance().setBackButtonTitlePositionAdjustment(UIOffset(horizontal: -9999, vertical: 0), for: .default)
        UITableViewCell.appearance().selectedBackgroundView = colorView
        UITableViewCell.appearance().backgroundColor = UIColor.clear
        UITableView.appearance().sectionIndexColor = UIColor.lightGray
        UITableView.appearance().sectionIndexBackgroundColor = UIColor.clear
        UITableView.appearance().separatorStyle = .none
        UITableView.appearance().separatorColor = UIColor.white
        UITextField.appearance().textColor = UIColor.white
        UISwitch.appearance().onTintColor = MuzBlueColor
        
        UVStyleSheet.instance().navigationBarBackgroundColor = UIColor.clear
        UVStyleSheet.instance().navigationBarTintColor = UIColor.white
        UVStyleSheet.instance().navigationBarTextColor = UIColor.white
        UVStyleSheet.instance().tintColor = UIColor.black
        
        let mainScreen = UIScreen.main
        let window = UIWindow(frame: mainScreen.bounds)
        
        let tabbar = TabBarController()
        let nav = NavBarController(rootViewController: ArtistsViewController())
        let navPlaylists = NavBarController(rootViewController: PlaylistsViewController())
        let navSongs = NavBarController(rootViewController: SongsViewController())
        let navMore = NavBarController(rootViewController: MoreViewController())
        let navHome = NavBarController(rootViewController: HomeViewController())
        
        tabbar.setViewControllers([nav, navSongs, navHome, navPlaylists, navMore], animated: false)
        tabbar.selectedIndex = 2
        window.rootViewController = tabbar
        
        window.makeKeyAndVisible()
        
        return window
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        // Preloads keyboard so there's no lag on initial keyboard appearance.
        let lagFreeField: UITextField = UITextField()
        self.window?.addSubview(lagFreeField)
        lagFreeField.becomeFirstResponder()
        lagFreeField.resignFirstResponder()
        lagFreeField.removeFromSuperview()
        
    
        let types: UIUserNotificationType = ([.alert, .badge, .sound])
        let settings = UIUserNotificationSettings(types: types, categories: nil)
        application.registerUserNotificationSettings(settings)
        application.registerForRemoteNotifications()
        
        if UserDefaults.standard.object(forKey: "FirstTimer") == nil {
            SettingsManager.defaultManager.updateValueForMoreSetting(.lyrics, value: NSNumber(value: true as Bool))
            UserDefaults.standard.set(NSNumber(value: false as Bool), forKey: "FirstTimer")
        }
        
        self.window = muzWindow()
        
        let config = UVConfig(site: "nytekproductions.uservoice.com")
        config?.forumId = forumID
        
        UserVoice.initialize(config)
        
        Appirater.setAppId("951709415")
        Appirater.setCustomAlertTitle("Rate Muz")
        Appirater.setCustomAlertMessage("If you enjoy using Muz, would you mind taking a moment to rate it? It won't take more than a minute. Thanks for your support!")
        Appirater.setCustomAlertRateButtonTitle("Rate Muz")
        Appirater.setDaysUntilPrompt(2)
        Appirater.setUsesUntilPrompt(5)
        Appirater.appLaunched(true)
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        
        NotificationCenter.default.removeObserver(self,
            name: NSNotification.Name.MPMediaLibraryDidChange,
            object: nil)
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
        Appirater.appEnteredForeground(true)
        
        MPMediaLibrary.default().beginGeneratingLibraryChangeNotifications()
        NotificationCenter.default.addObserver(self,
            selector: #selector(AppDelegate.updateLibrary(_:)),
            name: NSNotification.Name.MPMediaLibraryDidChange,
            object: nil)
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        MediaSession.sharedSession.syncUnscrobbledSongs()
    }

    func applicationWillTerminate(_ application: UIApplication) {
        MPMusicPlayerController.iPodMusicPlayer().stop()
    }
    
    func updateLibrary(_ obj: Notification) {
        print(obj.userInfo, terminator: "")
        if let _ = obj.object as? MPMediaLibrary {
            DataManager.manager.datastore.resetLibrary({ (error) -> () in
                DataManager.manager.syncArtists({ (addedItems, error) -> () in
                    DataManager.manager.syncPlaylists({ (addedItems, error) -> () in
                        
                    })
                    
                    }, progress: { (addedItems, total) -> () in
                })
            })
        }
    }
    
    func application(_ application: UIApplication, handleWatchKitExtensionRequest userInfo: [AnyHashable: Any]?, reply: (@escaping ([AnyHashable: Any]?) -> Void)) {
        if let action = userInfo?["action"] as? String {
            
            let result = Dictionary<String, AnyObject>()
            
            if action == "pausePlay" {
                if MPMusicPlayerController.iPodMusicPlayer().playbackState == .playing {
                    MPMusicPlayerController.iPodMusicPlayer().pause()
                } else {
                    MPMusicPlayerController.iPodMusicPlayer().play()
                }
            }
            
            reply(result)
        }
    }
}

