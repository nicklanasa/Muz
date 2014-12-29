//
//  Song+Helpers.swift
//  Muz
//
//  Created by Nick Lanasa on 12/7/14.
//
//

import Foundation
import CoreData
import MediaPlayer

extension Song: Printable {
    func parseItem(item: MPMediaItem) {
        
        self.persistentID = NSNumber(unsignedLongLong: item.persistentID)
        
        self.mediaType = item.mediaType.rawValue
        
        if let title = item.title {
            self.title = title
        }
        
        if let albumTitle = item.albumTitle {
            self.albumTitle = albumTitle
        }
        
        if let artist = item.artist {
            self.artist = artist
        }
        
        if let albumArtist = item.albumArtist {
            self.albumArtist = albumArtist
        }
        
        if let genre = item.genre {
            self.genre = genre
        }
        
        if let composer = item.composer {
            self.composer = composer
        }
        
        self.playbackDuration = item.playbackDuration
        self.albumTrackNumber = item.albumTrackNumber
        self.discNumber = item.discNumber
        
        if item.respondsToSelector("lyrics") {
            if let lyrics = item.lyrics {
                self.lyrics = lyrics
            }
        }
        
        if item.respondsToSelector("compilation") {
            self.compilation = item.compilation
        }
        
        if let releaseDate = item.releaseDate {
            self.releaseDate = releaseDate
        }
        
        if item.respondsToSelector("beatsPerMinute") {
            self.beatsPerMinute = item.beatsPerMinute
        }
        
        if item.respondsToSelector("comments") {
            if let comments = item.comments {
                self.comments = comments
            }
        }
        
        if let assetURL = item.assetURL {
            if let url = assetURL.absoluteString {
                self.assetURL = url
            }
        }
        
        self.cloudItem = item.cloudItem
        self.playCount = item.playCount
        self.skipCount = item.skipCount
        self.rating = item.rating
        
        if let podcastTitle = item.podcastTitle {
            self.podcastTitle = podcastTitle
        }
        
        if let lastPlayedDate = item.lastPlayedDate {
            self.lastPlayedDate = lastPlayedDate
        }
        
        if let userGrouping = item.userGrouping {
            self.userGrouping = userGrouping
        }
        
        self.bookmarkTime = item.bookmarkTime
    }
}
