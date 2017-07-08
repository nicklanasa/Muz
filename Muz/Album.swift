//
//  Album.swift
//  Muz
//
//  Created by Nick Lanasa on 2/6/15.
//  Copyright (c) 2015 Nytek Productions. All rights reserved.
//

import Foundation
import CoreData

@objc(Album)
class Album: NSManagedObject {

    @NSManaged var persistentID: String
    @NSManaged var releaseDate: Date?
    @NSManaged var title: String
    @NSManaged var artist: Artist
    @NSManaged var songs: NSSet

}
