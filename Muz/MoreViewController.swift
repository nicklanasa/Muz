//
//  MoreViewController.swift
//  Muz
//
//  Created by Nick Lanasa on 12/9/14.
//  Copyright (c) 2014 Nytek Productions. All rights reserved.
//

import Foundation
import UIKit
import CoreData

enum MoreSectionType: NSInteger {
    case Settings
    case Info
}

enum MoreSetting: NSInteger {
    case Sync
    case ArtistInfo
    case Lyrics
    case LastFM
}

class MoreViewController: RootViewController,
    UITableViewDelegate,
    UITableViewDataSource,
    LastFmLoginCellDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    var hud: MBProgressHUD!
    var isSigningIn = false
    
    // Make this DB driven
    private let tableDataSectionSettings = ["Sync iPod library", "Artist info", "Lyrics", "Last.fm"]
    private let tableDataSectionInfo = ["Rate app", "Facebook", "Twitter", "Website", "Feedback"]
    
    private let lyricsSwitch = UISwitch(frame: CGRectMake(0, 0, 50, 50))
    private let backgroundArtworkSwitch = UISwitch(frame: CGRectMake(0, 0, 50, 50))
    private let artistInfoSwitch = UISwitch(frame: CGRectMake(0, 0, 50, 50))
    
    var lastfmLoginCell: LastFmLoginCell!
    
    override init() {
        super.init(nibName: "MoreViewController", bundle: nil)
        
        self.tabBarItem = UITabBarItem(title: nil,
            image: UIImage(named: "more"),
            selectedImage: UIImage(named: "more"))
        self.tabBarItem.imageInsets = UIEdgeInsetsMake(6, 0, -6, 0)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewWillAppear(animated: Bool) {
        self.screenName = "More"
        super.viewWillAppear(animated)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.registerNib(UINib(nibName: "MoreLastFmSettingCell", bundle: nil), forCellReuseIdentifier: "LastFmCell")
        self.tableView.registerNib(UINib(nibName: "LastFmLoginCell", bundle: nil), forCellReuseIdentifier: "LastFmLoginCell")
        self.tableView.registerClass(NSClassFromString("UITableViewCell"), forCellReuseIdentifier: "Cell")
        self.tableView.registerNib(UINib(nibName: "SongsHeader", bundle: nil), forHeaderFooterViewReuseIdentifier: "Header")
        
        self.lyricsSwitch.addTarget(self, action: "updatedSetting:", forControlEvents: .ValueChanged)
        self.artistInfoSwitch.addTarget(self, action: "updatedSetting:", forControlEvents: .ValueChanged)
        
        let lastFmLoginCellCellNib = UINib(nibName: "LastFmLoginCell", bundle: nil)
        lastfmLoginCell = lastFmLoginCellCellNib.instantiateWithOwner(self, options: nil)[0] as? LastFmLoginCell
        lastfmLoginCell.lastfmSwitch.addTarget(self, action: "updatedSetting:", forControlEvents: .ValueChanged)
        lastfmLoginCell.delegate = self
        
        
    }
    
    func dismissKeyboard() {
        self.lastfmLoginCell.usernameTextfield.resignFirstResponder()
        self.lastfmLoginCell.passwordTextfield.resignFirstResponder()
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case MoreSectionType.Settings.rawValue: return self.tableDataSectionSettings.count
        default: return self.tableDataSectionInfo.count
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        var cell = tableView.dequeueReusableCellWithIdentifier("Cell",
            forIndexPath: indexPath) as UITableViewCell
        
        cell.textLabel?.font = MuzSettingFont
        cell.textLabel?.text = ""
        cell.textLabel?.textAlignment = .Left
        
        switch indexPath.section {
        case MoreSectionType.Settings.rawValue:
            switch indexPath.row {
            case MoreSetting.ArtistInfo.rawValue:
                var lastFmCell = tableView.dequeueReusableCellWithIdentifier("LastFmCell") as MoreLastFmSettingCell
                lastFmCell.artistInfoSwitch.on = SettingsManager.defaultManager.valueForMoreSetting(.ArtistInfo)
                lastFmCell.artistInfoSwitch.addTarget(self, action: "updatedSetting:", forControlEvents: .ValueChanged)
                return lastFmCell
            default:
                if indexPath.row == 0 {
                    cell.textLabel?.textAlignment = .Center
                    cell.textLabel?.font = MuzTitleFont
                    
                    cell.textLabel?.text = self.tableDataSectionSettings[indexPath.row] as NSString
                    
                } else if indexPath.row == 3 {
                    lastfmLoginCell.lastfmSwitch.on = SettingsManager.defaultManager.valueForMoreSetting(.LastFM)
                    lastfmLoginCell.lastfmSwitch.addTarget(self, action: "updatedSetting:", forControlEvents: .ValueChanged)
                    
                    lastfmLoginCell.lastfmSwitch.tag = indexPath.row
                    
                    return lastfmLoginCell
                } else {
                    self.lyricsSwitch.on = SettingsManager.defaultManager.valueForMoreSetting(.Lyrics)
                    cell.accessoryView = self.lyricsSwitch
                    
                    cell.textLabel?.text = self.tableDataSectionSettings[indexPath.row] as NSString
                }
            }
        default:
            cell.textLabel?.text = self.tableDataSectionInfo[indexPath.row] as NSString
            cell.accessoryType = .DisclosureIndicator
        }
        
        cell.textLabel?.textColor = UIColor.whiteColor()
        
        return cell
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        switch indexPath.section {
        case MoreSectionType.Settings.rawValue:
            switch indexPath.row {
            default:
                if indexPath.row == 3 {
                    if self.isSigningIn {
                        return 206
                    }
                }
            }
        default: break
        }
        
        return 55
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        switch indexPath.section {
        case MoreSectionType.Settings.rawValue:
            if indexPath.row == 0 {
                self.hud = MBProgressHUD.showHUDAddedTo(self.view, animated: true)
                self.hud.mode = MBProgressHUDModeDeterminate
                self.hud.labelText = "Syncing library..."
                self.hud.labelFont = MuzTitleFont
                DataManager.manager.syncArtists({ (addedItems, error) -> () in
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        self.hud.hide(true)
                    })
                    
                    DataManager.manager.syncPlaylists({ (addedItems, error) -> () in
                    
                    })
                }, progress: { (addedItems, total) -> () in
                    self.hud.progress = Float(addedItems.count) / Float(total)
                })
            }
        default:
            switch indexPath.row {
            case 0: UIApplication.sharedApplication().openURL(NSURL(string: "https://itunes.apple.com/us/app/muz/id951709415?ls=1&mt=8")!)
            case 1: UIApplication.sharedApplication().openURL(NSURL(string: "https://www.facebook.com/muzapp?ref=bookmarks")!)
            case 2: UIApplication.sharedApplication().openURL(NSURL(string: "https://twitter.com/muz_app")!)
            case 3: UIApplication.sharedApplication().openURL(NSURL(string: "http://nytekproductions.com/muz/")!)
            default:
                UserVoice.presentUserVoiceInterfaceForParentViewController(self)
            }
        }
        
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    func updatedSetting(sender: AnyObject) {
        if let settingSwitch = sender as? UISwitch {
            let value = NSNumber(bool: settingSwitch.on)
            if settingSwitch == self.lyricsSwitch {
                SettingsManager.defaultManager.updateValueForMoreSetting(.Lyrics, value: value)
            } else if settingSwitch == lastfmLoginCell.lastfmSwitch {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    if !settingSwitch.on {
                        self.isSigningIn = false
                        self.dismissKeyboard()
                        
                        LastFm.sharedInstance().logout()
                        
                        NSUserDefaults.standardUserDefaults().setObject(nil, forKey: "LastFMUsername")
                        NSUserDefaults.standardUserDefaults().setObject(nil, forKey: "LastFMPassword")
                        
                        SettingsManager.defaultManager.updateValueForMoreSetting(.LastFM, value: NSNumber(bool: false))
                        self.tableView.scrollEnabled = true
                    } else {
                        self.tableView.scrollToRowAtIndexPath(NSIndexPath(forItem: self.lastfmLoginCell.lastfmSwitch.tag, inSection: 0),
                            atScrollPosition: .Top,
                            animated: true)
                        self.tableView.scrollEnabled = false
                        self.isSigningIn = true
                    }
                    
                    self.tableView.beginUpdates()
                    self.tableView.endUpdates()
                })
            
            } else {
                SettingsManager.defaultManager.updateValueForMoreSetting(.ArtistInfo, value: value)
            }
        }
    }
    
    func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        if self.isSigningIn {
            self.isSigningIn = false
            self.dismissKeyboard()
            
            self.tableView.beginUpdates()
            self.tableView.endUpdates()
        }
    }
    
    func lastFmLoginCellDidTapLoginButton(cell: LastFmLoginCell) {
        var hud = MBProgressHUD.showHUDAddedTo(self.view, animated: true)
        hud.mode = MBProgressHUDModeIndeterminate
        hud.labelText = "Please wait..."
        hud.labelFont = MuzTitleFont
        
        LastFm.sharedInstance().getSessionForUser(cell.usernameTextfield.text, password: cell.passwordTextfield.text, successHandler: { (userData) -> Void in
            hud.hide(true)
            SettingsManager.defaultManager.updateValueForMoreSetting(.LastFM, value: NSNumber(bool: true))
            print(userData)
            
            let session = userData["key"] as String
            NSUserDefaults.standardUserDefaults().setObject(cell.usernameTextfield.text, forKey: "LastFMUsername")
            NSUserDefaults.standardUserDefaults().setObject(cell.passwordTextfield.text, forKey: "LastFMPassword")
            NSUserDefaults.standardUserDefaults().setObject(session, forKey: "LastFMSession")
            
            self.isSigningIn = false
            
            self.dismissKeyboard()
            
            self.tableView.beginUpdates()
            self.tableView.endUpdates()
            
            self.tableView.scrollEnabled = true
            
            LocalyticsSession.shared().tagEvent("Lastfm Login")
        }) { (error) -> Void in
            hud.hide(true)
            self.tableView.scrollEnabled = true
            LocalyticsSession.shared().tagEvent("Failed Lastfm Login")
            UIAlertView(title: "Error!",
                message: "Unable to login to Last.fm, please check your username and password.",
                delegate: self,
                cancelButtonTitle: "Ok").show()
        }
    }
}