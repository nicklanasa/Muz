//
//  Playlist.swift
//  Muz
//
//  Created by Nick Lanasa on 2/7/15.
//  Copyright (c) 2015 Nytek Productions. All rights reserved.
//

import Foundation
import CoreData

@objc(Playlist)
class Playlist: NSManagedObject {

    @NSManaged var name: String
    @NSManaged var persistentID: String
    @NSManaged var playlistType: NSNumber
    @NSManaged var modifiedDate: NSDate
    @NSManaged var playlistSongs: NSSet

}
