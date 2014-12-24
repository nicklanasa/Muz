//
//  LastFmAlbumBuyLinksRequest.swift
//  Muz
//
//  Created by Nick Lanasa on 12/16/14.
//  Copyright (c) 2014 Nytek Productions. All rights reserved.
//

import Foundation

protocol LastFmAlbumBuyLinksRequestDelegate {
    func lastFmAlbumBuyLinksRequestDidComplete(request: LastFmAlbumBuyLinksRequest, didCompleteWithBuyLinks buyLinks: [AnyObject]?)
}

class LastFmAlbumBuyLinksRequest: LastFmRequest {
    
    let artist: NSString!
    let album: NSString!
    var delegate: LastFmAlbumBuyLinksRequestDelegate?
    
    init(artist: NSString, album: NSString) {
        self.artist = artist
        self.album = album
    }
    
    override func sendURLRequest() {
        super.sendURLRequest()
        var lastFm = LastFm.sharedInstance()
        lastFm.apiKey = self.apiKey
        lastFm.apiSecret = self.apiSecret
        lastFm.session = "albumBuyLinksSession"
        
        lastFm.getBuyLinksForAlbum(self.album, artist: self.artist, country: "USA", successHandler: { (buyLinks) -> Void in
            if self.delegate != nil {
                
                var links = NSMutableArray()
                
                for buyLinksJSON in buyLinks {
                    if let JSON = buyLinksJSON as? NSDictionary {
                        links.addObject(LastFmBuyLink(JSON: JSON))
                    }
                }
                
                self.connectionDidFinishLoading(NSURLConnection())
                self.delegate!.lastFmAlbumBuyLinksRequestDidComplete(self, didCompleteWithBuyLinks: links)
            }

        }) { (error) -> Void in
            self.connectionDidFinishLoading(NSURLConnection())
            self.delegate!.lastFmAlbumBuyLinksRequestDidComplete(self, didCompleteWithBuyLinks: [])
        }
        
    }
    
    override func connectionDidFinishLoading(connection: NSURLConnection) {
        super.connectionDidFinishLoading(connection)
    }
}