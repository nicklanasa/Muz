//
//  LastFmTopAlbumsRequest.swift
//  Muz
//
//  Created by Nick Lanasa on 2/9/15.
//  Copyright (c) 2015 Nytek Productions. All rights reserved.
//

import Foundation

protocol LastFmTopAlbumsRequestDelegate {
    func lastFmTopAlbumsRequestDidComplete(_ request: LastFmTopAlbumsRequest, didCompleteWithAlbums albums: [AnyObject]?)
}

class LastFmTopAlbumsRequest: LastFmRequest {
    
    let artist: String!
    var delegate: LastFmTopAlbumsRequestDelegate?
    
    init(artist: String) {
        self.artist = artist
    }
    
    override func sendURLRequest() {
        super.sendURLRequest()
        let lastFm = LastFm.sharedInstance()
        lastFm?.apiKey = self.apiKey
        lastFm?.apiSecret = self.apiSecret
        lastFm?.session = "topAlbumsSession"
        
        lastFm?.getTopAlbums(forArtist: self.artist, successHandler: { (results) -> Void in
            let albums = NSMutableArray()
            
            for album in results! {
                if let JSON = album as? NSDictionary {
                    albums.add(LastFmAlbum(json: JSON as! [AnyHashable: Any]))
                }
            }
            
            self.connectionDidFinishLoading(NSURLConnection())
            self.delegate!.lastFmTopAlbumsRequestDidComplete(self, didCompleteWithAlbums: albums as [AnyObject])
        }) { (error) -> Void in
            self.connectionDidFinishLoading(NSURLConnection())
            self.delegate!.lastFmTopAlbumsRequestDidComplete(self, didCompleteWithAlbums: [])
        }
    }
}
