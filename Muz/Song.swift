//
//  Song.swift
//  Muz
//
//  Created by Nick Lanasa on 12/7/14.
//
//

import Foundation
import CoreData
import MediaPlayer

@objc(Song)
class Song: NSManagedObject {

    @NSManaged var mediaType: NSNumber
    @NSManaged var title: String
    @NSManaged var albumTitle: String
    @NSManaged var artist: String
    @NSManaged var albumArtist: String
    @NSManaged var genre: String
    @NSManaged var composer: String
    @NSManaged var playbackDuration: NSNumber
    @NSManaged var albumTrackNumber: NSNumber
    @NSManaged var albumTrackCount: NSNumber
    @NSManaged var discNumber: NSNumber
    @NSManaged var discCount: NSNumber
    @NSManaged var lyrics: String
    @NSManaged var compilation: NSNumber
    @NSManaged var releaseDate: NSDate
    @NSManaged var beatsPerMinute: NSNumber
    @NSManaged var comments: String
    @NSManaged var assetURL: String
    @NSManaged var cloudItem: NSNumber
    @NSManaged var podcastTitle: String
    @NSManaged var playCount: NSNumber
    @NSManaged var skipCount: NSNumber
    @NSManaged var rating: NSNumber
    @NSManaged var lastPlayedDate: NSDate
    @NSManaged var userGrouping: String
    @NSManaged var bookmarkTime: NSNumber
}
