//
//  Playlist.swift
//  Muz
//
//  Created by Nick Lanasa on 12/16/14.
//  Copyright (c) 2014 Nytek Productions. All rights reserved.
//

import Foundation
import CoreData

@objc(Playlist)
class Playlist: NSManagedObject {

    @NSManaged var persistentID: String
    @NSManaged var name: String
    @NSManaged var playlistType: NSNumber
    @NSManaged var playlistSongs: NSSet

}
