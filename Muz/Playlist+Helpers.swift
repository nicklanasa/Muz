//
//  Playlist+Helpers.swift
//  Muz
//
//  Created by Nick Lanasa on 12/15/14.
//  Copyright (c) 2014 Nytek Productions. All rights reserved.
//

import Foundation
import MediaPlayer

enum PlaylistType: UInt {
    case None = 0
    case Smart = 1
    case Genius = 6
}

extension Playlist {
    func parsePlaylist(playlist: MPMediaPlaylist) {
        self.persistentID = String(playlist.persistentID)
        self.name = playlist.name ?? ""
        self.playlistType = NSNumber(unsignedLong: playlistTypeForPlaylist(playlist).rawValue)
        
    }
    
    func playlistTypeForPlaylist(playlist: MPMediaPlaylist) -> PlaylistType {
        print(playlist.name)
        let playlistAttribute = playlist.playlistAttributes
        switch playlistAttribute.rawValue {
        case PlaylistType.Genius.rawValue:
            return PlaylistType.Genius
        default:
            return PlaylistType.None
        }
    }
}