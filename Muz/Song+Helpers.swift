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

extension Song {
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
        
        if item.respondsToSelector("releaseDate") {
            if let releaseDate = item.releaseDate {
                self.releaseDate = releaseDate
            }
        }
        
        if item.respondsToSelector("beatsPerMinute") {
            self.beatsPerMinute = item.beatsPerMinute
        }
        
        if item.respondsToSelector("comments") {
            if let comments = item.comments {
                self.comments = comments
            }
        }
        
        if item.respondsToSelector("assetURL") {
            if let assetURL = item.assetURL {
                self.assetURL = assetURL.absoluteString
            }
        }
        
        if item.respondsToSelector("cloudItem") {
            self.cloudItem = item.cloudItem
        }
        
        if item.respondsToSelector("playCount") {
            self.playCount = item.playCount
        }
        
        if item.respondsToSelector("skipCount") {
            self.skipCount = item.skipCount
        }
        
        if item.respondsToSelector("rating") {
            self.rating = item.rating
        }
        
        if item.respondsToSelector("podcastTitle") {
            if let podcastTitle = item.podcastTitle {
                self.podcastTitle = podcastTitle
            }
        }
        
        if item.respondsToSelector("lastPlayedDate") {
            if let lastPlayedDate = item.lastPlayedDate {
                self.lastPlayedDate = lastPlayedDate
            }
        }
        
        if item.respondsToSelector("userGrouping") {
            if let userGrouping = item.userGrouping {
                self.userGrouping = userGrouping
            }
        }

        if item.respondsToSelector("bookmarkTime") {
            self.bookmarkTime = item.bookmarkTime
        }
    }
}
