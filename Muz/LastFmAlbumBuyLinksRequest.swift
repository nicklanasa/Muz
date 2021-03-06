//
//  LastFmAlbumBuyLinksRequest.swift
//  Muz
//
//  Created by Nick Lanasa on 12/16/14.
//  Copyright (c) 2014 Nytek Productions. All rights reserved.
//

import Foundation

protocol LastFmAlbumBuyLinksRequestDelegate {
    func lastFmAlbumBuyLinksRequestDidComplete(_ request: LastFmAlbumBuyLinksRequest, didCompleteWithBuyLinks buyLinks: [AnyObject]?)
}

class LastFmAlbumBuyLinksRequest: LastFmRequest {
    
    let artist: String!
    let album: String!
    var delegate: LastFmAlbumBuyLinksRequestDelegate?
    
    init(artist: String, album: String) {
        self.artist = artist
        self.album = album
    }
    
    override func sendURLRequest() {
        super.sendURLRequest()
        let lastFm = LastFm.sharedInstance()
        lastFm?.apiKey = self.apiKey
        lastFm?.apiSecret = self.apiSecret
        lastFm?.session = "albumBuyLinksSession"
        
        lastFm?.getBuyLinks(forAlbum: self.album, artist: self.artist, country: "USA", successHandler: { (buyLinks) -> Void in
            if self.delegate != nil {
                
                let links = NSMutableArray()
                
                for buyLinksJSON in buyLinks! {
                    if let JSON = buyLinksJSON as? NSDictionary {
                        links.add(LastFmBuyLink(json: JSON as! [AnyHashable: Any]))
                    }
                }
                
                self.connectionDidFinishLoading(NSURLConnection())
                self.delegate!.lastFmAlbumBuyLinksRequestDidComplete(self, didCompleteWithBuyLinks: links as [AnyObject])
            }

        }) { (error) -> Void in
            self.connectionDidFinishLoading(NSURLConnection())
            self.delegate!.lastFmAlbumBuyLinksRequestDidComplete(self, didCompleteWithBuyLinks: [])
        }
        
    }
    
    override func connectionDidFinishLoading(_ connection: NSURLConnection) {
        super.connectionDidFinishLoading(connection)
    }
}
