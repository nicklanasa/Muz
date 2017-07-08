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
    
    func valueForMoreSetting(_ setting: MoreSetting) -> Bool {
        switch setting {
        case .lyrics:
            if let lyrics = UserDefaults.standard.object(forKey: "lyrics") as? NSNumber {
                return lyrics.boolValue
            }
            
            return false
        case .artistInfo:
            if let artistInfo = UserDefaults.standard.object(forKey: "artistInfo") as? NSNumber {
                return artistInfo.boolValue
            }
            
            return false
            
        case .lastFM:
            if let lastFM = UserDefaults.standard.object(forKey: "lastFM") as? NSNumber {
                return lastFM.boolValue
            }
            
            return false
        default: return false
            
        }
    }
    
    func updateValueForMoreSetting(_ setting: MoreSetting, value: NSNumber) {
        switch setting {
        case .lyrics:
            UserDefaults.standard.set(value, forKey: "lyrics")
        case .artistInfo:
            UserDefaults.standard.set(value, forKey: "artistInfo")
        case .lastFM:
            UserDefaults.standard.set(value, forKey: "lastFM")
        default: break
            
        }
    }
}
