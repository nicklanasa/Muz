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
    
    func getEvents(_ location: String!, completion: @escaping (_ events: [AnyObject]?, _ error: NSError?) -> ()) {
        let lastFm = LastFm.sharedInstance()
        lastFm?.apiKey = self.apiKey
        lastFm?.apiSecret = self.apiSecret
        lastFm?.session = "geoEvents"
        
        lastFm?.getEventsForLocation(location, successHandler: { (results) -> Void in
            let events = NSMutableArray()
            for event in results as! [NSDictionary] {
                events.add(LastFmEvent(json: event as [AnyHashable: Any]))
            }
            
            completion(events: events as [AnyObject], error: nil)
        }) { (error) -> Void in
            completion(nil, error)
        } as! LastFmReturnBlockWithError as! LastFmReturnBlockWithError as! LastFmReturnBlockWithError as! LastFmReturnBlockWithError as! LastFmReturnBlockWithError
    }
}
