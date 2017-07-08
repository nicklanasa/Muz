//
//  LastFmSimiliarArtistsRequest.swift
//  Muz
//
//  Created by Nick Lanasa on 12/14/14.
//  Copyright (c) 2014 Nytek Productions. All rights reserved.
//

import Foundation

protocol LastFmSimiliarArtistsRequestDelegate {
    func lastFmSimiliarArtistsRequestDidComplete(_ request: LastFmSimiliarArtistsRequest, didCompleteWithLastFmArtists artists: [AnyObject]?)
}

class LastFmSimiliarArtistsRequest: LastFmRequest {
    
    let artist: String!
    var delegate: LastFmSimiliarArtistsRequestDelegate?
    
    var responseData = NSMutableData()
    
    init(artist: String) {
        self.artist = artist
    }
    
    override func sendURLRequest() {
        super.sendURLRequest()
        let lastFm = LastFm.sharedInstance()
        lastFm?.apiKey = self.apiKey
        lastFm?.apiSecret = self.apiSecret
        lastFm?.session = "similiarArtistsSession"
        
        lastFm?.getSimilarArtists(to: self.artist, successHandler: { (data) -> Void in
            
            let artists = NSMutableArray()
            
            for similiarArtistJSON in data! {
                if let JSON = similiarArtistJSON as? NSDictionary {
                    artists.add(LastFmArtist(json: JSON as! [AnyHashable: Any]))
                }
            }
            
            self.connectionDidFinishLoading(NSURLConnection())
            self.delegate?.lastFmSimiliarArtistsRequestDidComplete(self, didCompleteWithLastFmArtists: artists as [AnyObject])
        }) { (error) -> Void in
            self.connectionDidFinishLoading(NSURLConnection())
            self.delegate!.lastFmSimiliarArtistsRequestDidComplete(self, didCompleteWithLastFmArtists: [])
        }
    }
    
    override func connectionDidFinishLoading(_ connection: NSURLConnection) {
        super.connectionDidFinishLoading(connection)
    }
}
