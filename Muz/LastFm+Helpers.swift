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
    func scrobbleTracks(_ tracks: [AnyObject], completion: @escaping (_ results: AnyObject?, _ error: NSError?) -> ()) {
        
        let params = NSMutableDictionary()
        
        for i in 0 ..< tracks.count {
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
        
        LastFm.sharedInstance().performApiCall(forMethod: "track.scrobble",
            useCache: true,
            withParams: params as! [AnyHashable: Any],
            rootXpath: ".",
            returnDictionary: true,
            mappingObject: [:],
            successHandler: { (results) -> Void in
            completion(results, nil)
        } as! LastFmReturnBlockWithObject) { (error) -> Void in
            completion(nil, error)
        } as! LastFmReturnBlockWithError as! LastFmReturnBlockWithError as! LastFmReturnBlockWithError
    }
}
