//
//  Playlist+Helpers.swift
//  Muz
//
//  Created by Nick Lanasa on 12/15/14.
//  Copyright (c) 2014 Nytek Productions. All rights reserved.
//

import Foundation
import MediaPlayer

extension Playlist {
    func parsePlaylist(playlist: MPMediaPlaylist) {
        self.persistentID = String(playlist.persistentID)
        
        println(self.persistentID)
        self.name = playlist.name
    }
}