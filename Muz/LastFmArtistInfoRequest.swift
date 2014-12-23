//
//  LastFmArtistInfoRequest.swift
//  Muz
//
//  Created by Nick Lanasa on 12/14/14.
//  Copyright (c) 2014 Nytek Productions. All rights reserved.
//

import Foundation

protocol LastFmArtistInfoRequestDelegate {
    func lastFmArtistInfoRequestDidComplete(request: LastFmArtistInfoRequest, didCompleteWithLastFmArtist artist: LastFmArtist?)
}

class LastFmArtistInfoRequest: LastFmRequest {
    
    let artist: NSString!
    var delegate: LastFmArtistInfoRequestDelegate?
    
    var responseData = NSMutableData()
    
    init(artist: NSString) {
        self.artist = artist
    }
    
    func sendURLRequest() {
        var lastFm = LastFm.sharedInstance()
        lastFm.apiKey = "d55a72556285ca314e7af8b0fb093e29"
        lastFm.apiSecret = "affa81f90053b2114888298f3aeb27b9"
        lastFm.session = "artistInfoSession"
        
        lastFm.getInfoForArtist(self.artist, successHandler: { (info) -> Void in
            let artist = LastFmArtist(JSON: info)
            self.delegate?.lastFmArtistInfoRequestDidComplete(self, didCompleteWithLastFmArtist: artist)
        }) { (error) -> Void in

        }
    }
}