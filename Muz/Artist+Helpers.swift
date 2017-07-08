//
//  Artist+Helpers.swift
//  Muz
//
//  Created by Nick Lanasa on 2/3/15.
//  Copyright (c) 2015 Nytek Productions. All rights reserved.
//

import Foundation
import CoreData
import MediaPlayer

extension Artist {
    func parseItem(_ item: MPMediaItem) {
        
        self.persistentID = item.artistPersistentID.description
        
        if let name = item.artist {
            self.name = name
        }
    }
    
    func addAlbum(_ album: Album?) {
//        if let managedAlbum = album {
//            var found = false
//            for artistAlbum in self.albums.allObjects as [Album] {
//                if managedAlbum.title == artistAlbum.title {
//                    found = true
//                    break
//                }
//            }
//            
//            if !found {
//                var artistAlbums = NSMutableSet(set: self.albums)
//                artistAlbums.addObject(managedAlbum)
//                self.albums = artistAlbums
//            }
//        }
    }
}
