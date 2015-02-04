//
//  Artist.swift
//  Muz
//
//  Created by Nickolas Lanasa on 2/3/15.
//  Copyright (c) 2015 Nytek Productions. All rights reserved.
//

import Foundation
import CoreData

@objc(Artist)
class Artist: NSManagedObject {

    @NSManaged var name: String
    @NSManaged var persistentID: String
    @NSManaged var modifiedDate: NSDate
    @NSManaged var albums: NSSet

}
