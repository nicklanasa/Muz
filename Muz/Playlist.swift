//
//  Playlist.swift
//  Muz
//
//  Created by Nick Lanasa on 2/12/15.
//  Copyright (c) 2015 Nytek Productions. All rights reserved.
//

import Foundation
import CoreData

@objc(Playlist)
class Playlist: NSManagedObject {

    @NSManaged var modifiedDate: Date
    @NSManaged var name: String
    @NSManaged var persistentID: String?
    @NSManaged var playlistType: NSNumber
    @NSManaged var playlistSongs: NSSet

}
