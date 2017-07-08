//
//  Song.swift
//  Muz
//
//  Created by Nick Lanasa on 2/6/15.
//  Copyright (c) 2015 Nytek Productions. All rights reserved.
//

import Foundation
import CoreData

@objc(Song)
class Song: NSManagedObject {

    @NSManaged var albumArtist: String
    @NSManaged var albumTitle: String
    @NSManaged var albumTrackCount: NSNumber
    @NSManaged var albumTrackNumber: NSNumber
    @NSManaged var artist: String
    @NSManaged var assetURL: String
    @NSManaged var beatsPerMinute: NSNumber
    @NSManaged var bookmarkTime: NSNumber
    @NSManaged var cloudItem: NSNumber
    @NSManaged var comments: String
    @NSManaged var compilation: NSNumber
    @NSManaged var composer: String
    @NSManaged var discCount: NSNumber
    @NSManaged var discNumber: NSNumber
    @NSManaged var genre: String
    @NSManaged var lastPlayedDate: Date
    @NSManaged var lyrics: String
    @NSManaged var mediaType: NSNumber
    @NSManaged var persistentID: NSNumber
    @NSManaged var playbackDuration: NSNumber
    @NSManaged var playCount: NSNumber
    @NSManaged var podcastTitle: String
    @NSManaged var rating: NSNumber
    @NSManaged var releaseDate: Date
    @NSManaged var skipCount: NSNumber
    @NSManaged var title: String
    @NSManaged var userGrouping: String
    @NSManaged var album: Album
    @NSManaged var artists: NSSet
    @NSManaged var playlists: NSSet

}
