//
//  MusicSession.swift
//  Muz
//
//  Created by Nick Lanasa on 12/7/14.
//
//

import Foundation
import CoreData
import MediaPlayer

let _sharedSession = MediaSession()

//protocol MediaSessionDelegate {
//    func mediaSessionDidUpdate
//}

@objc class MediaSession {
    
    let dataManager = DataManager.manager
    
    
    class var sharedSession : MediaSession {
        return _sharedSession
    }
    
    func openSessionWithUpdateBlock(updateBlock: (percentage: Float, error: NSErrorPointer, song: Song?) -> ()) {
        let everything = MPMediaQuery()
        let results = everything.items
        dataManager.datastore.addSongs(results, updateBlock: { (percentage, error, song) -> () in
            updateBlock(percentage: percentage, error: error, song: song)
        })
    }
    
    func infoForArtists() -> NSArray {
        
        var artistsArr = NSMutableArray()
        let query = MPMediaQuery.albumsQuery()
        let results = query.collections as NSArray
        return results
    }
    
    func artworkForSongs() -> NSArray {
        var artistsArr = NSMutableArray()
        let query = MPMediaQuery.songsQuery()
        let results = query.items as NSArray
        return results
    }
    
    
}
