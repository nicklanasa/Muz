//
//  MusicSession.swift
//  Muz
//
//  Created by Nick Lanasa on 12/7/14.
//
//

import Foundation
import CoreData
import MediaPlayer

let _sharedSession = MediaSession()

//protocol MediaSessionDelegate {
//    func mediaSessionDidUpdate
//}

@objc class MediaSession {
    
    let dataManager = DataManager.manager
    
    
    class var sharedSession : MediaSession {
        return _sharedSession
    }
    
    func openSessionWithUpdateBlock(updateBlock: (percentage: Float, error: NSErrorPointer, song: Song?) -> ()) {
        let everything = MPMediaQuery()
        let results = everything.items
        
        dataManager.datastore.addPlaylists()
        
        dataManager.datastore.addSongs(results, updateBlock: { (percentage, error, song) -> () in
            updateBlock(percentage: percentage, error: error, song: song)
        })
    }
    
    func infoForArtists() -> NSArray {
        
        var artistsArr = NSMutableArray()
        let query = MPMediaQuery.albumsQuery()
        let results = query.collections as NSArray
        return results
    }
    
    func artworkForSongs() -> NSArray {
        var artistsArr = NSMutableArray()
        let query = MPMediaQuery.songsQuery()
        let results = query.items as NSArray
        return results
    }
    
    // Artists
    
    func artistsCollectionWithQuery(artistsQuery: MPMediaQuery) -> [AnyObject]? {
        return artistsQuery.collections
    }
    
    func artistsQueryWithFilters(filters: [MPMediaPredicate]?) -> MPMediaQuery {
        let artistsQuery = MPMediaQuery.artistsQuery()
        
        if let predicates = filters {
            for predicate in predicates {
                artistsQuery.addFilterPredicate(predicate)
            }
        }
        
        return artistsQuery
    }
    
    func artistsSectionIndexTitles(artistsQuery: MPMediaQuery) -> [AnyObject] {
        var artistsSections = NSMutableArray()
        if let sections = artistsQuery.collectionSections {
            for section in sections {
                if let songSection = section as? MPMediaQuerySection {
                    artistsSections.addObject(songSection.title)
                }
            }
        }
        
        return artistsSections
    }
    
    func playlistSongsForPlaylist(playlist: Playlist) -> MPMediaQuery {
        println(playlist.persistentID.toInt())
        let predicate = MPMediaPropertyPredicate(value: playlist.persistentID.toInt(),
            forProperty: MPMediaPlaylistPropertyPersistentID,
            comparisonType: .EqualTo)
        let playlistSongsQuery = MPMediaQuery.playlistsQuery()
        playlistSongsQuery.addFilterPredicate(predicate)
        return playlistSongsQuery
    }
    
    func itemForSong(song: Song) -> MPMediaItem? {
        let query = MPMediaQuery.songsQuery()
        let predicate = MPMediaPropertyPredicate(value: song.persistentID,
            forProperty: MPMediaItemPropertyPersistentID,
            comparisonType: .EqualTo)
        query.addFilterPredicate(predicate)
        
        if query.items.count > 0 {
            return query.items[0] as? MPMediaItem
        } else {
            return nil
        }
    }
    
    func collectionWithPlaylistSongs(songs: [AnyObject]) -> MPMediaItemCollection {
        var items = NSMutableArray()
        
        for playlistSong in songs as [PlaylistSong] {
            var query = MPMediaQuery.songsQuery()
            println(playlistSong.song.persistentID)
            let predicate = MPMediaPropertyPredicate(value: playlistSong.song.persistentID,
                forProperty: MPMediaItemPropertyPersistentID,
                comparisonType: .EqualTo)
            query.addFilterPredicate(predicate)
            items.addObjectsFromArray(query.items)
        }
        
        println(items)
        
        return MPMediaItemCollection(items: items)
    }
}
