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
    case none = 0
    case smart = 1
    case genius = 6
}

extension Playlist {
    func parsePlaylist(_ playlist: MPMediaPlaylist) {
        self.persistentID = String(playlist.persistentID)
        self.name = playlist.name ?? ""
        self.playlistType = NSNumber(value: playlistTypeForPlaylist(playlist).rawValue as UInt)
        
    }
    
    func playlistTypeForPlaylist(_ playlist: MPMediaPlaylist) -> PlaylistType {
        print(playlist.name)
        let playlistAttribute = playlist.playlistAttributes
        switch playlistAttribute.rawValue {
        case PlaylistType.genius.rawValue:
            return PlaylistType.genius
        default:
            return PlaylistType.none
        }
    }
}
