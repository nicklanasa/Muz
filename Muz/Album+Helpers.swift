//
//  Album+Helpers.swift
//  Muz
//
//  Created by Nick Lanasa on 2/3/15.
//  Copyright (c) 2015 Nytek Productions. All rights reserved.
//

import Foundation
import CoreData
import MediaPlayer

extension Album {
    func parseItem(_ item: MPMediaItem) {
        
        self.persistentID = item.albumPersistentID.description
        
        if let title = item.albumTitle {
            self.title = title
        } else {
            self.title = "Unknown album"
        }
        
        if let releaseDate = item.releaseDate {
            self.releaseDate = releaseDate
        }
    }
    
    func addSong(_ song: Song?) {
        if let managedSong = song {
            var found = false
            for albumSong in self.songs.allObjects as! [Song] {
                if managedSong.title == albumSong.title {
                    found = true
                    break
                }
            }
            
            if !found {
                let albumSongs = NSMutableSet(set: self.songs)
                albumSongs.add(managedSong)
                self.songs = NSSet(set: albumSongs)
            }
        }
    }
}
