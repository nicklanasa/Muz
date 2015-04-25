//
//  Muz+ItunesSearch.swift
//  Muz
//
//  Created by Nickolas Lanasa on 3/15/15.
//  Copyright (c) 2015 Nytek Productions. All rights reserved.
//

import Foundation

extension ItunesSearch {
    
    typealias SearchCompletion = (error: NSError?, results: NSArray) -> ()
    
    func getAlbums(album: String, limit: Int, completion: SearchCompletion) {
        var params = NSMutableDictionary(dictionary: ["term" : album, "media" : "music", "entity" : "album"])
        
        if limit > 0 {
           params["limit"] = limit
        }
        
        
        self.performApiCallForMethod("search", withParams: params as [NSObject : AnyObject], andFilters: [:], successHandler: { (albums) -> Void in
            completion(error: nil, results: albums as! NSArray)
        }) { (error) -> Void in
            completion(error: error, results: [])
        }
    }
    
    func getTracks(track: String, limit: Int, completion: SearchCompletion) {
        var params = NSMutableDictionary(dictionary: ["term" : track, "media" : "music", "entity" : "musicTrack"])
        
        if limit > 0 {
            params["limit"] = limit
        }
        
        
        self.performApiCallForMethod("search", withParams: params as [NSObject : AnyObject], andFilters: [:], successHandler: { (tracks) -> Void in
            completion(error: nil, results: tracks as! NSArray)
            }) { (error) -> Void in
                completion(error: error, results: [])
        }
    }
}