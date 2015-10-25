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
    
    let artist: String!
    var delegate: LastFmArtistInfoRequestDelegate?
    
    var responseData = NSMutableData()
    
    init(artist: String) {
        self.artist = artist
    }
    
    override func sendURLRequest() {
        super.sendURLRequest()
        let lastFm = LastFm.sharedInstance()
        lastFm.apiKey = "d55a72556285ca314e7af8b0fb093e29"
        lastFm.apiSecret = "affa81f90053b2114888298f3aeb27b9"
        lastFm.session = "artistInfoSession"
        
        lastFm.getInfoForArtist(self.artist, successHandler: { (info) -> Void in
            let artist = LastFmArtist(JSON: info)
            self.connectionDidFinishLoading(NSURLConnection())
            self.delegate?.lastFmArtistInfoRequestDidComplete(self, didCompleteWithLastFmArtist: artist)
        }) { (error) -> Void in
            self.connectionDidFinishLoading(NSURLConnection())
        }
    }
    
    override func connectionDidFinishLoading(connection: NSURLConnection) {
        super.connectionDidFinishLoading(connection)
    }
}