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
    func parsePlaylistSong(_ song: Song, playlist: Playlist, originalPlaylist: MPMediaPlaylist?) {
        self.song = song
        self.playlists = NSSet(object: playlist)
        
        if let p = originalPlaylist {
            var count = 0
            for item in p.items {
                if song.title == item.title {
                    self.order = NSNumber(value: count as Int)
                    break
                }
                count += 1
            }
        } else {
            self.order = NSNumber(value: 0 as UInt64)
        }
    }
    
    func updatePlaylistSong(_ song: Song, playlist: Playlist, originalPlaylist: MPMediaPlaylist?) {
        self.song = song
        
        let playlists = NSMutableSet(set: self.playlists)
        
        self.playlists.enumerateObjects { (obj, idx) -> Void in
            if let songPlaylist = obj as? Playlist {
                if songPlaylist.persistentID == playlist.persistentID {
                    playlists.remove(songPlaylist)
                    playlists.add(playlist)
                }
            }
        }
        
        self.playlists = playlists
        
        if let p = originalPlaylist {
            var count = 0
            for item in p.items {
                if song.title == item.title {
                    self.order = NSNumber(value: count as Int)
                    break
                }
                count += 1
            }
        } else {
            self.order = NSNumber(value: 0 as UInt64)
        }
    }
    
    func parseSong(_ song: Song, playlist: Playlist, order: Int) {
        self.song = song
        
        let playlists = NSMutableSet(set: self.playlists)
        playlists.add(playlist)
        self.playlists = playlists
        
        self.order = NSNumber(value: order as Int)
    }
}
