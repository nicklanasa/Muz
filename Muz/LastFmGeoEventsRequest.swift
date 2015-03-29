//
//  LastFmGeoEventsRequest.swift
//  Muz
//
//  Created by Nickolas Lanasa on 3/28/15.
//  Copyright (c) 2015 Nytek Productions. All rights reserved.
//

import Foundation

class LastFmGeoEventsRequest: LastFmRequest {
    
    let location: NSString!
    
    init(location: NSString) {
        self.location = location
    }
    
    func getEvents(completion: () -> (results: [AnyObject], error: NSError?)) {
        super.sendURLRequest()
        var lastFm = LastFm.sharedInstance()
        lastFm.apiKey = self.apiKey
        lastFm.apiSecret = self.apiSecret
        lastFm.session = "geoEvents"
        
        lastFm.getEventsForLocation(self.location, successHandler: { (results) -> Void in
            print(results)
        }) { (error) -> Void in
            
        }
    }
}