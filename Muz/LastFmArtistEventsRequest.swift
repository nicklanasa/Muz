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
    
    let artist: NSString!
    var delegate: LastFmArtistEventsRequestDelegate?
    
    init(artist: NSString) {
        self.artist = artist
    }
    
    override func sendURLRequest() {
        super.sendURLRequest()
        var lastFm = LastFm.sharedInstance()
        lastFm.apiKey = self.apiKey
        lastFm.apiSecret = self.apiSecret
        lastFm.session = "artistsEventsSession"
        
        lastFm.getEventsForArtist(self.artist, successHandler: { (eventsArray) -> Void in
            if self.delegate != nil {
                
                var events = NSMutableArray()
                
                for eventsJSON in eventsArray {
                    if let JSON = eventsJSON as? NSDictionary {
                        events.addObject(LastFmEvent(JSON: JSON))
                    }
                }
                
                self.connectionDidFinishLoading(NSURLConnection())
                self.delegate!.lastFmArtistEventsRequestDidComplete(self, didCompleteWithEvents: events)
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