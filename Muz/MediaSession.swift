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
    let albumsQuery = MPMediaQuery.albumsQuery()
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

    func fetchImageForArtist(#artist: Artist, completion: (image: UIImage?) -> ()) {
        
        self.removeAllPredicatesFromQuert(artistsQuery)
        
        artistsQuery.addFilterPredicate(MPMediaPropertyPredicate(value: artist.name,
            forProperty: MPMediaItemPropertyArtist,
            comparisonType: .Contains))
        
        var image: UIImage?
        if artistsQuery.items.count > 0 {
            for item in artistsQuery.items as [MPMediaItem] {
                if let artwork = item.artwork {
                    if let artistImage = artwork.imageWithSize(CGSizeMake(50, 50)) {
                        image = artistImage
                        break
                    }
                }
            }
        }
        
        completion(image: image)
    }
    
    // MARK: Albums
    
    func fetchAlbumCollectionForAlbum(#album: Album, completion: (collection: MPMediaItemCollection) -> ()) {
        self.removeAllPredicatesFromQuert(albumsQuery)
        
        albumsQuery.addFilterPredicate(MPMediaPropertyPredicate(value: album.title,
            forProperty: MPMediaItemPropertyAlbumTitle,
            comparisonType: .Contains))
        
        completion(collection: MPMediaItemCollection(items: albumsQuery.items))
    }
    
    func fetchAlbumsForArtist(#artist: Artist, completion: (results: [AnyObject]) -> ()) {
        self.removeAllPredicatesFromQuert(albumsQuery)
        albumsQuery.addFilterPredicate(MPMediaPropertyPredicate(value: artist.persistentID, forProperty: MPMediaItemPropertyArtistPersistentID, comparisonType: .EqualTo))
        completion(results: albumsQuery.items)
    }
    
    func fetchImageForAlbum(#album: Album, completion: (image: UIImage?) -> ()) {
        
        self.removeAllPredicatesFromQuert(albumsQuery)
        
        albumsQuery.addFilterPredicate(MPMediaPropertyPredicate(value: album.title,
            forProperty: MPMediaItemPropertyAlbumTitle,
            comparisonType: .Contains))
        
        var image: UIImage?
        if albumsQuery.items.count > 0 {
            for item in albumsQuery.items as [MPMediaItem] {
                if let artwork = item.artwork {
                    if let albumImage = artwork.imageWithSize(CGSizeMake(50, 50)) {
                        image = albumImage
                        break
                    }
                }
            }
        }
        
        completion(image: image)
    }
    
    // MARK: Songs
    
    func fetchItemForSong(song: Song) -> MPMediaItem? {
        
        self.removeAllPredicatesFromQuert(songsQuery)
        
        let predicate = MPMediaPropertyPredicate(value: song.persistentID,
            forProperty: MPMediaItemPropertyPersistentID,
            comparisonType: .EqualTo)
        
        songsQuery.addFilterPredicate(predicate)
        
        if songsQuery.items.count > 0 {
            return songsQuery.items[0] as? MPMediaItem
        } else {
            return nil
        }
    }
    
    func fetchImageForSong(#song: Song, completion: (image: UIImage?) -> ()) {
        
        self.removeAllPredicatesFromQuert(songsQuery)
        
        songsQuery.addFilterPredicate(MPMediaPropertyPredicate(value: song.title,
            forProperty: MPMediaItemPropertyTitle,
            comparisonType: .Contains))
        
        var image: UIImage?
        if songsQuery.items.count > 0 {
            for item in songsQuery.items as [MPMediaItem] {
                if let artwork = item.artwork {
                    if let songImage = artwork.imageWithSize(CGSizeMake(50, 50)) {
                        image = songImage
                        break
                    }
                }
            }
        }
        
        completion(image: image)
    }
    
    func fetchSongs(completion: (results: [AnyObject]) -> ()) {
        let songsQuery = MPMediaQuery.songsQuery()
        completion(results: songsQuery.items)
    }
    
    // Helpers
    
    func removeAllPredicatesFromQuert(query: MPMediaQuery) {
        for predicate in query.filterPredicates.allObjects as [MPMediaPropertyPredicate] {
            query.removeFilterPredicate(predicate)
        }
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
