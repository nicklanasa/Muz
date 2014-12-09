//
//  MusicSession.swift
//  Muz
//
//  Created by Nick Lanasa on 12/7/14.
//
//

import Foundation
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
    
    func openSessionWithCompletionBlock(completionBlock: (success: Bool) -> ()) {
        let everything = MPMediaQuery()
        let results = everything.items
        dataManager.datastore.addSongs(results, completion: { (success) -> () in
            completionBlock(success: success)
        })
    }
}
