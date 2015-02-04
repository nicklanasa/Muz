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

@objc class MediaSession {
    
    let dataManager = DataManager.manager
    let artistsQuery = MPMediaQuery.artistsQuery()
    let songsQuery = MPMediaQuery.songsQuery()
    
    var isMediaLibraryEmpty: Bool {
        get {
            var query = MPMediaQuery.songsQuery()
            return query.items.count == 0
        }
    }
    
    /**
    Handles updated the Datastore when iTunes library is updated
    */
    func mediaLibraryDidChange() {
        
    }
    
    class var sharedSession : MediaSession {
        return _sharedSession
    }
    
    // Artists
    
    func fetchArtists(completion: (results: [AnyObject]) -> ()) {
        completion(results: artistsQuery.items)
    }
    
    func fetchAlbumsForArtist(#artist: Artist, completion: (results: [AnyObject]) -> ()) {
        let albumsQuery = MPMediaQuery.albumsQuery()
        albumsQuery.addFilterPredicate(MPMediaPropertyPredicate(value: artist.persistentID, forProperty: MPMediaItemPropertyArtistPersistentID, comparisonType: .EqualTo))
        completion(results: albumsQuery.items)
    }
    
    func fetchImageForArtist(#artist: Artist, completion: (image: UIImage?) -> ()) {
        let artists = MPMediaQuery.artistsQuery()
        artists.addFilterPredicate(MPMediaPropertyPredicate(value: artist.name,
            forProperty: MPMediaItemPropertyArtist,
            comparisonType: .Contains))
        
        var image: UIImage?
        if artists.items.count > 0 {
            for item in artists.items as [MPMediaItem] {
                if let artwork = item.artwork {
                    if let artistImage = artwork.imageWithSize(CGSizeMake(50, 50)) {
                        print("Found image\n")
                        image = artistImage
                        break
                    }
                }
            }
        }
        
        completion(image: image)
    }
    
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
    
    func songsQueryWithPredicate(predicate: MPMediaPropertyPredicate?) -> MPMediaQuery {
        var songsQuery = MPMediaQuery.songsQuery()
        
        if let p = predicate {
            songsQuery?.addFilterPredicate(p)
        }
        
        return songsQuery
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
        let typePredicate = MPMediaPropertyPredicate(value: MPMediaType.AnyAudio.rawValue,
            forProperty: MPMediaItemPropertyMediaType,
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
