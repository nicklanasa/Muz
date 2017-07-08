//
//  Muz+ItunesSearch.swift
//  Muz
//
//  Created by Nickolas Lanasa on 3/15/15.
//  Copyright (c) 2015 Nytek Productions. All rights reserved.
//

import Foundation

extension ItunesSearch {
    
    typealias SearchCompletion = (_ error: NSError?, _ results: NSArray) -> ()
    
    func getAlbums(_ album: String, limit: Int, completion: @escaping SearchCompletion) {
        let params = NSMutableDictionary(dictionary: ["term" : album, "media" : "music", "entity" : "album"])
        
        if limit > 0 {
           params["limit"] = limit
        }
        
        
        self.performApiCall(forMethod: "search", withParams: params as! [AnyHashable: Any], andFilters: [:], successHandler: { (albums) -> Void in
            completion(nil, albums as! NSArray)
        }) { (error) -> Void in
            completion(error, [])
        } as! ItunesSearchReturnBlockWithError as! ItunesSearchReturnBlockWithError as! ItunesSearchReturnBlockWithError as! ItunesSearchReturnBlockWithError
    }
    
    func getTracks(_ track: String, limit: Int, completion: @escaping SearchCompletion) {
        let params = NSMutableDictionary(dictionary: ["term" : track, "media" : "music", "entity" : "musicTrack"])
        
        if limit > 0 {
            params["limit"] = limit
        }
        
        
        self.performApiCall(forMethod: "search", withParams: params as! [AnyHashable: Any], andFilters: [:], successHandler: { (tracks) -> Void in
            completion(nil, tracks as! NSArray)
            }) { (error) -> Void in
                completion(error, [])
        } as! ItunesSearchReturnBlockWithError as! ItunesSearchReturnBlockWithError as! ItunesSearchReturnBlockWithError as! ItunesSearchReturnBlockWithError
    }
}
