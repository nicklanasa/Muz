//
//  LastFmTopAlbumsRequest.swift
//  Muz
//
//  Created by Nick Lanasa on 2/9/15.
//  Copyright (c) 2015 Nytek Productions. All rights reserved.
//

import Foundation

protocol LastFmTopAlbumsRequestDelegate {
    func lastFmTopAlbumsRequestDidComplete(request: LastFmTopAlbumsRequest, didCompleteWithAlbums albums: [AnyObject]?)
}

class LastFmTopAlbumsRequest: LastFmRequest {
    
    let artist: NSString!
    var delegate: LastFmTopAlbumsRequestDelegate?
    
    init(artist: NSString) {
        self.artist = artist
    }
    
    override func sendURLRequest() {
        super.sendURLRequest()
        var lastFm = LastFm.sharedInstance()
        lastFm.apiKey = self.apiKey
        lastFm.apiSecret = self.apiSecret
        lastFm.session = "topAlbumsSession"
        
        lastFm.getTopAlbumsForArtist(self.artist, successHandler: { (results) -> Void in
            var albums = NSMutableArray()
            
            for album in results {
                if let JSON = album as? NSDictionary {
                    albums.addObject(LastFmAlbum(JSON: JSON))
                }
            }
            
            self.connectionDidFinishLoading(NSURLConnection())
            self.delegate!.lastFmTopAlbumsRequestDidComplete(self, didCompleteWithAlbums: albums)
        }) { (error) -> Void in
            self.connectionDidFinishLoading(NSURLConnection())
            self.delegate!.lastFmTopAlbumsRequestDidComplete(self, didCompleteWithAlbums: [])
        }
    }
}