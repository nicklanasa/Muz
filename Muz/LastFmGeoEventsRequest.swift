//
//  LastFmGeoEventsRequest.swift
//  Muz
//
//  Created by Nickolas Lanasa on 3/28/15.
//  Copyright (c) 2015 Nytek Productions. All rights reserved.
//

import Foundation

let _sharedRequest = LastFmGeoEventsRequest()

class LastFmGeoEventsRequest: LastFmRequest {
    
    class var sharedRequest: LastFmGeoEventsRequest {
        return _sharedRequest
    }
    
    func getEvents(location: NSString!, completion: (events: [AnyObject]?, error: NSError?) -> ()) {
        var lastFm = LastFm.sharedInstance()
        lastFm.apiKey = self.apiKey
        lastFm.apiSecret = self.apiSecret
        lastFm.session = "geoEvents"
        
        lastFm.getEventsForLocation(location, successHandler: { (results) -> Void in
            var events = NSMutableArray()
            for event in results as [NSDictionary] {
                events.addObject(LastFmEvent(JSON: event))
            }
            
            completion(events: events, error: nil)
        }) { (error) -> Void in
            completion(events: nil, error: error)
        }
    }
}