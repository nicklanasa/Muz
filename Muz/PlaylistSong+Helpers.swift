//
//  PlaylistSong+Helpers.swift
//  Muz
//
//  Created by Nick Lanasa on 12/15/14.
//  Copyright (c) 2014 Nytek Productions. All rights reserved.
//

import Foundation
import MediaPlayer

extension PlaylistSong {
    func parsePlaylistSong(song: Song, playlist: Playlist, originalPlaylist: MPMediaPlaylist?) {
        self.song = song
        self.playlists = NSSet(object: playlist)
        
        if let p = originalPlaylist {
            var count = 0
            for item in p.items {
                if song.title == item.title {
                    self.order = NSNumber(integer: count)
                    break
                }
                count++
            }
        } else {
            self.order = NSNumber(unsignedLongLong: 0)
        }
    }
    
    func updatePlaylistSong(song: Song, playlist: Playlist, originalPlaylist: MPMediaPlaylist?) {
        self.song = song
        
        let playlists = NSMutableSet(set: self.playlists)
        
        self.playlists.enumerateObjectsUsingBlock { (obj, idx) -> Void in
            if let songPlaylist = obj as? Playlist {
                if songPlaylist.persistentID == playlist.persistentID {
                    playlists.removeObject(songPlaylist)
                    playlists.addObject(playlist)
                }
            }
        }
        
        if let p = originalPlaylist {
            var count = 0
            for item in p.items {
                if song.title == item.title {
                    self.order = NSNumber(integer: count)
                    break
                }
                count++
            }
        } else {
            self.order = NSNumber(unsignedLongLong: 0)
        }
    }
}