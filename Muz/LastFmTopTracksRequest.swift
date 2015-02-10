//
//  LastFmTopTracksRequest.swift
//  Muz
//
//  Created by Nick Lanasa on 2/9/15.
//  Copyright (c) 2015 Nytek Productions. All rights reserved.
//

import Foundation

protocol LastFmTopTracksRequestDelegate {
    func lastFmTopTracksRequestDidComplete(request: LastFmTopTracksRequest, didCompleteWithTracks tracks: [AnyObject]?)
}

class LastFmTopTracksRequest: LastFmRequest {
    
    let artist: NSString!
    var delegate: LastFmTopTracksRequestDelegate?
    
    init(artist: NSString) {
        self.artist = artist
    }
    
    override func sendURLRequest() {
        super.sendURLRequest()
        var lastFm = LastFm.sharedInstance()
        lastFm.apiKey = self.apiKey
        lastFm.apiSecret = self.apiSecret
        lastFm.session = "topTracksSession"
        
        lastFm.getTopTracksForArtist(self.artist, successHandler: { (results) -> Void in
            var tracks = NSMutableArray()
            
            for track in results {
                if let JSON = track as? NSDictionary {
                    tracks.addObject(LastFmTrack(JSON: JSON))
                }
            }
            
            self.connectionDidFinishLoading(NSURLConnection())
            self.delegate!.lastFmTopTracksRequestDidComplete(self, didCompleteWithTracks: tracks)
            }) { (error) -> Void in
                self.connectionDidFinishLoading(NSURLConnection())
                self.delegate!.lastFmTopTracksRequestDidComplete(self, didCompleteWithTracks: [])
            }
    }
}