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
    func parseItem(_ item: MPMediaItem) {
        
        self.persistentID = NSNumber(value: item.persistentID as UInt64)
        
        self.mediaType = NSNumber(item.mediaType.rawValue)
        
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
        
        self.playbackDuration = NSNumber(item.playbackDuration)
        
        self.albumTrackNumber = NSNumber(item.albumTrackNumber)
        self.discNumber = NSNumber(item.discNumber)
        
        if item.responds(to: #selector(getter: MPMediaItem.lyrics)) {
            if let lyrics = item.lyrics {
                self.lyrics = lyrics
            }
        }
        
        if item.responds(to: "compilation") {
            self.compilation = item.isCompilation as NSNumber
        }
        
        if item.responds(to: #selector(getter: MPMediaItem.releaseDate)) {
            if let releaseDate = item.releaseDate {
                self.releaseDate = releaseDate
            }
        }
        
        if item.responds(to: #selector(getter: MPMediaItem.beatsPerMinute)) {
            self.beatsPerMinute = NSNumber(item.beatsPerMinute)
        }
        
        if item.responds(to: #selector(getter: MPMediaItem.comments)) {
            if let comments = item.comments {
                self.comments = comments
            }
        }
        
        if item.responds(to: #selector(getter: MPMediaItem.assetURL)) {
            if let assetURL = item.assetURL {
                self.assetURL = assetURL.absoluteString
            }
        }
        
        if item.responds(to: "cloudItem") {
            self.cloudItem = item.isCloudItem as NSNumber
        }
        
        if item.responds(to: #selector(getter: MPMediaItem.playCount)) {
            self.playCount = NSNumber(item.playCount)
        }
        
        if item.responds(to: #selector(getter: MPMediaItem.skipCount)) {
            self.skipCount = NSNumber(item.skipCount)
        }
        
        if item.responds(to: #selector(getter: MPMediaItem.rating)) {
            self.rating = NSNumber(item.rating)
        }
        
        if item.responds(to: #selector(getter: MPMediaItem.podcastTitle)) {
            if let podcastTitle = item.podcastTitle {
                self.podcastTitle = podcastTitle
            }
        }
        
        if item.responds(to: #selector(getter: MPMediaItem.lastPlayedDate)) {
            if let lastPlayedDate = item.lastPlayedDate {
                self.lastPlayedDate = lastPlayedDate
            }
        }
        
        if item.responds(to: #selector(getter: MPMediaItem.userGrouping)) {
            if let userGrouping = item.userGrouping {
                self.userGrouping = userGrouping
            }
        }

        if item.responds(to: #selector(getter: MPMediaItem.bookmarkTime)) {
            self.bookmarkTime = NSNumber(item.bookmarkTime)
        }
    }
}
