//
//  LastFm+Helpers.swift
//  Muz
//
//  Created by Nick Lanasa on 5/10/15.
//  Copyright (c) 2015 Nytek Productions. All rights reserved.
//

import Foundation
import MediaPlayer

extension LastFm {
    func scrobbleTracks(tracks: [AnyObject], completion: (results: AnyObject?, error: NSError?) -> ()) {
        
        let params = NSMutableDictionary()
        
        for var i = 0; i < tracks.count; i++ {
            if let track = tracks[i] as? MPMediaItem {
                // Only scrobble the last 50
                if i > 49 {
                    break
                }
                
                if let playedDate = track.lastPlayedDate {
                    params.setValue(track.artist, forKey: "artist[\(i)]")
                    params.setValue(track.albumTitle, forKey: "album[\(i)]")
                    params.setValue(track.title, forKey: "track[\(i)]")
                    params.setValue(floor(playedDate.timeIntervalSince1970 - track.playbackDuration), forKey: "timestamp[\(i)]")
                }
            }
        }
        
        LastFm.sharedInstance().performApiCallForMethod("track.scrobble",
            useCache: true,
            withParams: params as [NSObject : AnyObject],
            rootXpath: ".",
            returnDictionary: true,
            mappingObject: [:],
            successHandler: { (results) -> Void in
            completion(results: results, error: nil)
        }) { (error) -> Void in
            completion(results: nil, error: error)
        }
    }
}