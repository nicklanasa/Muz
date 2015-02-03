//
//  Artist.swift
//  Muz
//
//  Created by Nick Lanasa on 2/3/15.
//  Copyright (c) 2015 Nytek Productions. All rights reserved.
//

import Foundation
import CoreData

@objc(Artist)
class Artist: NSManagedObject {

    @NSManaged var name: String
    @NSManaged var persistentID: String
    @NSManaged var albums: NSSet

}
