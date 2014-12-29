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
    case Lyrics
    case ArtistInfo
}

class MoreViewController: RootViewController,
    UITableViewDelegate,
    UITableViewDataSource,
NSFetchedResultsControllerDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    // Make this DB driven
    let tableDataSectionSettings = ["Lyrics", "Artist info"]
    let tableDataSectionInfo = ["Rate app", "Facebook", "Twitter", "Website", "Feedback"]
    
    let lyricsSwitch = UISwitch(frame: CGRectMake(0, 0, 50, 50))
    let backgroundArtworkSwitch = UISwitch(frame: CGRectMake(0, 0, 50, 50))
    let artistInfoSwitch = UISwitch(frame: CGRectMake(0, 0, 50, 50))
    
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
        
        tableView.registerClass(NSClassFromString("UITableViewCell"), forCellReuseIdentifier: "Cell")
        tableView.registerNib(UINib(nibName: "SongsHeader", bundle: nil), forHeaderFooterViewReuseIdentifier: "Header")
        
        lyricsSwitch.addTarget(self, action: "updatedSetting:", forControlEvents: .ValueChanged)
        artistInfoSwitch.addTarget(self, action: "updatedSetting:", forControlEvents: .ValueChanged)
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case MoreSectionType.Settings.rawValue: return tableDataSectionSettings.count
        default: return tableDataSectionInfo.count
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell",
            forIndexPath: indexPath) as UITableViewCell
        
        switch indexPath.section {
        case MoreSectionType.Settings.rawValue:
            cell.textLabel?.text = tableDataSectionSettings[indexPath.row] as NSString
            switch indexPath.row {
            case MoreSetting.ArtistInfo.rawValue:
                artistInfoSwitch.on = SettingsManager.defaultManager.valueForMoreSetting(.ArtistInfo)
                cell.accessoryView = artistInfoSwitch
            default:
                lyricsSwitch.on = SettingsManager.defaultManager.valueForMoreSetting(.Lyrics)
                cell.accessoryView = lyricsSwitch
            }
        default:
            cell.textLabel?.text = tableDataSectionInfo[indexPath.row] as NSString
            cell.accessoryType = .DisclosureIndicator
        }
        
        cell.textLabel?.font = MuzSettingFont
        cell.textLabel?.textColor = UIColor.whiteColor()
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        switch indexPath.section {
        case MoreSectionType.Settings.rawValue:
            break;
        default:
            switch indexPath.row {
            case 0: UIApplication.sharedApplication().openURL(NSURL(string: "itms-apps://itunes.apple.com/app/951709415")!)
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
            if settingSwitch == lyricsSwitch {
                SettingsManager.defaultManager.updateValueForMoreSetting(.Lyrics, value: value)
            } else {
                SettingsManager.defaultManager.updateValueForMoreSetting(.ArtistInfo, value: value)
            }
        }
    }
}