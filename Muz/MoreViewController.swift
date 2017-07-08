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
    case settings
    case info
}

enum MoreSetting: NSInteger {
    case sync
    case lyrics
    case artistInfo
    case lastFM
}

class MoreViewController: RootViewController,
UITableViewDelegate,
UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    
    var syncingHud: MBProgressHUD!
    
    // Make this DB driven
    fileprivate let tableDataSectionSettings = ["Sync iPod library", "Lyrics"]
    fileprivate let tableDataSectionInfo = ["Rate app", "Facebook", "Twitter", "Website", "Feedback"]
    
    fileprivate let lyricsSwitch = UISwitch(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
    fileprivate let backgroundArtworkSwitch = UISwitch(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
    
    init() {
        super.init(nibName: "MoreViewController", bundle: nil)
        
        self.tabBarItem = UITabBarItem(title: nil,
            image: UIImage(named: "more"),
            selectedImage: UIImage(named: "more"))
        self.tabBarItem.imageInsets = UIEdgeInsetsMake(6, 0, -6, 0)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.screenName = "More"
        super.viewWillAppear(animated)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.register(UINib(nibName: "MoreLastFmSettingCell", bundle: nil), forCellReuseIdentifier: "LastFmCell")
        self.tableView.register(UINib(nibName: "LastFmLoginCell", bundle: nil), forCellReuseIdentifier: "LastFmLoginCell")
        self.tableView.register(NSClassFromString("UITableViewCell"), forCellReuseIdentifier: "Cell")
        self.tableView.register(UINib(nibName: "SongsHeader", bundle: nil), forHeaderFooterViewReuseIdentifier: "Header")
        
        self.lyricsSwitch.addTarget(self, action: #selector(MoreViewController.updatedSetting(_:)), for: .valueChanged)
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case MoreSectionType.settings.rawValue: return self.tableDataSectionSettings.count
        default: return self.tableDataSectionInfo.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell",
            for: indexPath) 
        
        cell.textLabel?.font = MuzSettingFont
        cell.textLabel?.text = ""
        cell.textLabel?.textAlignment = .left
        
        switch indexPath.section {
        case MoreSectionType.settings.rawValue:
            switch indexPath.row {
            default:
                if indexPath.row == 0 {
                    cell.textLabel?.textAlignment = .center
                    cell.textLabel?.font = MuzTitleFont
                    
                    cell.textLabel?.text = self.tableDataSectionSettings[indexPath.row] as String
                    
                } else {
                    self.lyricsSwitch.isOn = SettingsManager.defaultManager.valueForMoreSetting(.lyrics)
                    cell.accessoryView = self.lyricsSwitch
                    
                    cell.textLabel?.text = self.tableDataSectionSettings[indexPath.row] as String
                }
            }
        default:
            cell.textLabel?.text = self.tableDataSectionInfo[indexPath.row] as String
            cell.accessoryType = .disclosureIndicator
        }
        
        cell.textLabel?.textColor = UIColor.white
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 55
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.section {
        case MoreSectionType.settings.rawValue:
            if indexPath.row == 0 {
                self.syncingHud = MBProgressHUD.showAdded(to: self.view, animated: true)
                self.syncingHud.mode = .determinateHorizontalBar
                self.syncingHud.labelText = "Syncing library..."
                self.syncingHud.labelFont = MuzTitleFont
                DataManager.manager.syncArtists({ (addedItems, error) -> () in
                    DispatchQueue.main.async(execute: { () -> Void in
                        self.syncingHud.hide(true)
                    })
                    
                    DataManager.manager.syncPlaylists({ (addedItems, error) -> () in
                    
                    })
                    
                }, progress: { (addedItems, total) -> () in
                    self.syncingHud.progress = Float(addedItems.count) / Float(total)
                })
            }
        default:
            switch indexPath.row {
            case 0: UIApplication.shared.openURL(URL(string: "https://itunes.apple.com/us/app/muz/id951709415?ls=1&mt=8")!)
            case 1: UIApplication.shared.openURL(URL(string: "https://www.facebook.com/muzapp?ref=bookmarks")!)
            case 2: UIApplication.shared.openURL(URL(string: "https://twitter.com/muz_app")!)
            case 3: UIApplication.shared.openURL(URL(string: "http://nytekproductions.com/muz/")!)
            default:
                UserVoice.presentInterface(forParentViewController: self)
            }
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func updatedSetting(_ sender: AnyObject) {
        if let settingSwitch = sender as? UISwitch {
            let value = NSNumber(value: settingSwitch.isOn as Bool)
            if settingSwitch == self.lyricsSwitch {
                SettingsManager.defaultManager.updateValueForMoreSetting(.lyrics, value: value)
            }
        }
    }
}
