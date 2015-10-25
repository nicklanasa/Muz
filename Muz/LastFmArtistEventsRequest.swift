//
//  LastFmArtistImagesRequest.swift
//  Muz
//
//  Created by Nick Lanasa on 12/16/14.
//  Copyright (c) 2014 Nytek Productions. All rights reserved.
//

import Foundation

protocol LastFmArtistEventsRequestDelegate {
    func lastFmArtistEventsRequestDidComplete(request: LastFmArtistEventsRequest, didCompleteWithEvents events: [AnyObject]?)
}

class LastFmArtistEventsRequest: LastFmRequest {
    
    let artist: String!
    var delegate: LastFmArtistEventsRequestDelegate?
    
    init(artist: String) {
        self.artist = artist
    }
    
    override func sendURLRequest() {
        super.sendURLRequest()
        let lastFm = LastFm.sharedInstance()
        lastFm.apiKey = self.apiKey
        lastFm.apiSecret = self.apiSecret
        lastFm.session = "artistsEventsSession"
        
        lastFm.getEventsForArtist(self.artist, successHandler: { (eventsArray) -> Void in
            if self.delegate != nil {
                
                let events = NSMutableArray()
                
                for eventsJSON in eventsArray {
                    if let JSON = eventsJSON as? NSDictionary {
                        events.addObject(LastFmEvent(JSON: JSON as [NSObject : AnyObject]))
                    }
                }
                
                self.connectionDidFinishLoading(NSURLConnection())
                self.delegate!.lastFmArtistEventsRequestDidComplete(self, didCompleteWithEvents: events as [AnyObject])
            }
        }) { (error) -> Void in
            self.connectionDidFinishLoading(NSURLConnection())
            self.delegate!.lastFmArtistEventsRequestDidComplete(self, didCompleteWithEvents: [])
            
        }
    }
    
    override func connectionDidFinishLoading(connection: NSURLConnection) {
        super.connectionDidFinishLoading(connection)
    }
}