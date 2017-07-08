//
//  LastFmTrackBuyLinksRequest.swift
//  Muz
//
//  Created by Nick Lanasa on 12/16/14.
//  Copyright (c) 2014 Nytek Productions. All rights reserved.
//

import Foundation

protocol LastFmTrackBuyLinksRequestDelegate {
    func lastFmTrackBuyLinksRequestDidComplete(_ request: LastFmTrackBuyLinksRequest, didCompleteWithBuyLinks buyLinks: [AnyObject]?)
}

class LastFmTrackBuyLinksRequest: LastFmRequest {
    
    let artist: String!
    let title: String!
    var delegate: LastFmTrackBuyLinksRequestDelegate?
    
    init(artist: String, title: String) {
        self.artist = artist
        self.title = title
    }
    
    override func sendURLRequest() {
        let lastFm = LastFm.sharedInstance()
        lastFm?.apiKey = self.apiKey
        lastFm?.apiSecret = self.apiSecret
        lastFm?.session = "trackBuyLinksSession"
        
        lastFm?.getBuyLinks(forTrack: self.title, artist: self.artist, country: "USA", successHandler: { (buyLinks) -> Void in
            if self.delegate != nil {
                
                let links = NSMutableArray()
                
                for buyLinksJSON in buyLinks! {
                    if let JSON = buyLinksJSON as? NSDictionary {
                        links.add(LastFmBuyLink(json: JSON as! [AnyHashable: Any]))
                    }
                }
                
                self.connectionDidFinishLoading(NSURLConnection())
                self.delegate!.lastFmTrackBuyLinksRequestDidComplete(self, didCompleteWithBuyLinks: links as [AnyObject])
            }
        }) { (error) -> Void in
            self.connectionDidFinishLoading(NSURLConnection())
            self.delegate!.lastFmTrackBuyLinksRequestDidComplete(self, didCompleteWithBuyLinks: [])
        }
    }
    
    override func connectionDidFinishLoading(_ connection: NSURLConnection) {
        super.connectionDidFinishLoading(connection)
    }
}
