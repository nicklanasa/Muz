//
//  LastFmSimiliarArtistsRequest.swift
//  Muz
//
//  Created by Nick Lanasa on 12/14/14.
//  Copyright (c) 2014 Nytek Productions. All rights reserved.
//

import Foundation

protocol LastFmSimiliarArtistsRequestDelegate {
    func lastFmSimiliarArtistsRequestDidComplete(request: LastFmSimiliarArtistsRequest, didCompleteWithLastFmArtists artists: [AnyObject]?)
}

class LastFmSimiliarArtistsRequest: LastFmRequest {
    
    let artist: NSString!
    var delegate: LastFmSimiliarArtistsRequestDelegate?
    
    var responseData = NSMutableData()
    
    init(artist: NSString) {
        self.artist = artist
    }
    
    func sendURLRequest() {
        var lastFm = LastFm.sharedInstance()
        lastFm.apiKey = self.apiKey
        lastFm.apiSecret = self.apiSecret
        lastFm.session = "similiarArtistsSession"
        
        lastFm.getSimilarArtistsTo(self.artist, successHandler: { (data) -> Void in
            
            var artists = NSMutableArray()
            
            for similiarArtistJSON in data {
                if let JSON = similiarArtistJSON as? NSDictionary {
                    artists.addObject(LastFmArtist(JSON: JSON))
                }
            }
            
            self.delegate?.lastFmSimiliarArtistsRequestDidComplete(self, didCompleteWithLastFmArtists: artists)
        }) { (error) -> Void in
            self.delegate!.lastFmSimiliarArtistsRequestDidComplete(self, didCompleteWithLastFmArtists: [])
        }
    }
}