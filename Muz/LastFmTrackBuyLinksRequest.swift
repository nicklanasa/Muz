//
//  LastFmTrackBuyLinksRequest.swift
//  Muz
//
//  Created by Nick Lanasa on 12/16/14.
//  Copyright (c) 2014 Nytek Productions. All rights reserved.
//

import Foundation

protocol LastFmTrackBuyLinksRequestDelegate {
    func lastFmTrackBuyLinksRequestDidComplete(request: LastFmTrackBuyLinksRequest, didCompleteWithBuyLinks buyLinks: [AnyObject]?)
}

class LastFmTrackBuyLinksRequest: LastFmRequest {
    
    let artist: NSString!
    let title: NSString!
    var delegate: LastFmTrackBuyLinksRequestDelegate?
    
    init(artist: NSString, title: NSString) {
        self.artist = artist
        self.title = title
    }
    
    func sendURLRequest() {
        var lastFm = LastFm.sharedInstance()
        lastFm.apiKey = self.apiKey
        lastFm.apiSecret = self.apiSecret
        lastFm.session = "trackBuyLinksSession"
        
        lastFm.getBuyLinksForTrack(self.title, artist: self.artist, country: "USA", successHandler: { (buyLinks) -> Void in
            if self.delegate != nil {
                
                var links = NSMutableArray()
                
                for buyLinksJSON in buyLinks {
                    if let JSON = buyLinksJSON as? NSDictionary {
                        links.addObject(LastFmBuyLink(JSON: JSON))
                    }
                }
                
                self.delegate!.lastFmTrackBuyLinksRequestDidComplete(self, didCompleteWithBuyLinks: links)
            }
        }) { (error) -> Void in
            self.delegate!.lastFmTrackBuyLinksRequestDidComplete(self, didCompleteWithBuyLinks: [])
        }
    }
}