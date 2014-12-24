//
//  SettingsManager.swift
//  Muz
//
//  Created by Nick Lanasa on 12/23/14.
//  Copyright (c) 2014 Nytek Productions. All rights reserved.
//

import Foundation

let _defaultManager = SettingsManager()

class SettingsManager {
    
    class var defaultManager : SettingsManager {
        return _defaultManager
    }
    
    func valueForMoreSetting(setting: MoreSetting) -> Bool {
        switch setting {
        case .Cloud:
            if let cloud = NSUserDefaults.standardUserDefaults().objectForKey("cloud") as? NSNumber {
                return cloud.boolValue
            }
            
            return false
        case .Lyrics:
            if let lyrics = NSUserDefaults.standardUserDefaults().objectForKey("lyrics") as? NSNumber {
                return lyrics.boolValue
            }
            
            return false
        case .ArtistInfo:
            if let artistInfo = NSUserDefaults.standardUserDefaults().objectForKey("artistInfo") as? NSNumber {
                return artistInfo.boolValue
            }
            
            return false
        default: return false
            
        }
    }
    
    func updateValueForMoreSetting(setting: MoreSetting, value: NSNumber) {
        switch setting {
        case .Cloud:
            NSUserDefaults.standardUserDefaults().setObject(value, forKey: "cloud")
        case .Lyrics:
            NSUserDefaults.standardUserDefaults().setObject(value, forKey: "lyrics")
        case .ArtistInfo:
            NSUserDefaults.standardUserDefaults().setObject(value, forKey: "artistInfo")
        default: break
            
        }
    }
}
