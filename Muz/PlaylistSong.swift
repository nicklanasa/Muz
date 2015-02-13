//
//  PlaylistSong.swift
//  Muz
//
//  Created by Nick Lanasa on 2/12/15.
//  Copyright (c) 2015 Nytek Productions. All rights reserved.
//

import Foundation
import CoreData

@objc(PlaylistSong)
class PlaylistSong: NSManagedObject {

    @NSManaged var order: NSNumber
    @NSManaged var playlists: NSSet
    @NSManaged var song: Song

}
