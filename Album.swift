//
//  Album.swift
//  Muz
//
//  Created by Nick Lanasa on 2/5/15.
//  Copyright (c) 2015 Nytek Productions. All rights reserved.
//

import Foundation
import CoreData

@objc(Album)
class Album: NSManagedObject {

    @NSManaged var persistentID: String
    @NSManaged var title: String
    @NSManaged var releaseDate: NSDate
    @NSManaged var artists: NSSet
    @NSManaged var songs: NSSet

}
