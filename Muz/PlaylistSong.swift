//
//  PlaylistSong.swift
//  Muz
//
//  Created by Nick Lanasa on 12/15/14.
//  Copyright (c) 2014 Nytek Productions. All rights reserved.
//

import Foundation
import CoreData

@objc(PlaylistSong)
class PlaylistSong: NSManagedObject {

    @NSManaged var order: NSNumber
    @NSManaged var song: Song
    @NSManaged var playlists: NSSet

}
