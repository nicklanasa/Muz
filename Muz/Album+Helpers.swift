//
//  Album+Helpers.swift
//  Muz
//
//  Created by Nick Lanasa on 2/3/15.
//  Copyright (c) 2015 Nytek Productions. All rights reserved.
//

import Foundation
import CoreData
import MediaPlayer

extension Album {
    func parseItem(item: MPMediaItem) {
        
        self.persistentID = item.albumPersistentID.description
        
        if let title = item.albumTitle {
            self.title = title
        }
    }
}