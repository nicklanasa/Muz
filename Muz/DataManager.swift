//
//  DataManager.swift
//  FartyPants
//
//  Created by Nick Lanasa on 11/15/14.
//  Copyright (c) 2014 Nytek Productions. All rights reserved.
//

import Foundation
import CoreData
import MediaPlayer

let _manager = DataManager()

class DataManager {
    
    var datastore: Datastore!
    
    class var manager : DataManager {
        return _manager
    }
    
    init() {
        datastore = Datastore(storeName: "Muz")
    }
    
    func syncArtists(completion: (addedItems: [AnyObject], error: NSErrorPointer) -> ()) {
        MediaSession.sharedSession.fetchArtists { (results) -> () in
            self.datastore.addSongs(results, completion: { (addedItems, error) -> () in
                completion(addedItems: addedItems, error: error)
            })
        }
    }

}
