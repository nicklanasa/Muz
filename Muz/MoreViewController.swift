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
    case Lyrics
    case ArtistInfo
    case LastFM
}

class MoreViewController: RootViewController,
    UITableViewDelegate,
    UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    
    var hud: MBProgressHUD!
    
    // Make this DB driven
    private let tableDataSectionSettings = ["Sync iPod library", "Lyrics", "Artist info", "Last.fm"]
    private let tableDataSectionInfo = ["Rate app", "Facebook", "Twitter", "Website", "Feedback"]
    
    private let lyricsSwitch = UISwitch(frame: CGRectMake(0, 0, 50, 50))
    private let backgroundArtworkSwitch = UISwitch(frame: CGRectMake(0, 0, 50, 50))
    private let artistInfoSwitch = UISwitch(frame: CGRectMake(0, 0, 50, 50))
    private let lastFmLoginSwitch = UISwitch(frame: CGRectMake(0, 0, 50, 50))
    
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
        self.tableView.registerClass(NSClassFromString("UITableViewCell"), forCellReuseIdentifier: "Cell")
        self.tableView.registerNib(UINib(nibName: "SongsHeader", bundle: nil), forHeaderFooterViewReuseIdentifier: "Header")
        
        self.lyricsSwitch.addTarget(self, action: "updatedSetting:", forControlEvents: .ValueChanged)
        self.artistInfoSwitch.addTarget(self, action: "updatedSetting:", forControlEvents: .ValueChanged)
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
                } else if indexPath.row == 3 {
                    self.lastFmLoginSwitch.on = SettingsManager.defaultManager.valueForMoreSetting(.LastFM)
                    cell.accessoryView = self.lastFmLoginSwitch
                } else {
                    self.lyricsSwitch.on = SettingsManager.defaultManager.valueForMoreSetting(.Lyrics)
                    cell.accessoryView = self.lyricsSwitch
                }
                cell.textLabel?.text = self.tableDataSectionSettings[indexPath.row] as NSString
            }
        default:
            cell.textLabel?.text = self.tableDataSectionInfo[indexPath.row] as NSString
            cell.accessoryType = .DisclosureIndicator
        }
        
        cell.textLabel?.textColor = UIColor.whiteColor()
        
        return cell
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
            } else {
                SettingsManager.defaultManager.updateValueForMoreSetting(.ArtistInfo, value: value)
            }
        }
    }
}