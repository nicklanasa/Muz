//
//  LastFmTopTracksRequest.swift
//  Muz
//
//  Created by Nick Lanasa on 2/9/15.
//  Copyright (c) 2015 Nytek Productions. All rights reserved.
//

import Foundation

protocol LastFmTopTracksRequestDelegate {
    func lastFmTopTracksRequestDidComplete(_ request: LastFmTopTracksRequest, didCompleteWithTracks tracks: [AnyObject]?)
}

class LastFmTopTracksRequest: LastFmRequest {
    
    let artist: String!
    var delegate: LastFmTopTracksRequestDelegate?
    
    init(artist: String) {
        self.artist = artist
    }
    
    override func sendURLRequest() {
        super.sendURLRequest()
        let lastFm = LastFm.sharedInstance()
        lastFm?.apiKey = self.apiKey
        lastFm?.apiSecret = self.apiSecret
        lastFm?.session = "topTracksSession"
        
        lastFm?.getTopTracks(forArtist: self.artist, successHandler: { (results) -> Void in
            let tracks = NSMutableArray()
            
            for track in results! {
                if let JSON = track as? NSDictionary {
                    tracks.add(LastFmTrack(json: JSON as! [AnyHashable: Any]))
                }
            }
            
            self.connectionDidFinishLoading(NSURLConnection())
            self.delegate!.lastFmTopTracksRequestDidComplete(self, didCompleteWithTracks: tracks as [AnyObject])
            }) { (error) -> Void in
                self.connectionDidFinishLoading(NSURLConnection())
                self.delegate!.lastFmTopTracksRequestDidComplete(self, didCompleteWithTracks: [])
            }
    }
}
