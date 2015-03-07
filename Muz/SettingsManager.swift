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
            
        case .LastFM:
            if let lastFM = NSUserDefaults.standardUserDefaults().objectForKey("lastFM") as? NSNumber {
                return lastFM.boolValue
            }
            
            return false
        default: return false
            
        }
    }
    
    func updateValueForMoreSetting(setting: MoreSetting, value: NSNumber) {
        switch setting {
        case .Lyrics:
            NSUserDefaults.standardUserDefaults().setObject(value, forKey: "lyrics")
            LocalyticsSession.shared().tagEvent("Lyrics switch value updated.")
        case .ArtistInfo:
            NSUserDefaults.standardUserDefaults().setObject(value, forKey: "artistInfo")
            LocalyticsSession.shared().tagEvent("Artist info switch value updated.")
        case .LastFM:
            NSUserDefaults.standardUserDefaults().setObject(value, forKey: "lastFM")
            LocalyticsSession.shared().tagEvent("LastFM info switch value updated.")
        default: break
            
        }
    }
}
