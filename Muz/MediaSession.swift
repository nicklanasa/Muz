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

var CurrentQueueItems: MPMediaItemCollection!

@objc class MediaSession {
    
    let dataManager = DataManager.manager
    var artistsQuery = MPMediaQuery.artistsQuery()
    var albumsQuery = MPMediaQuery.albumsQuery()
    var songsQuery = MPMediaQuery.songsQuery()
    
    var currentQueueCollection: MPMediaItemCollection?
    
    var isMediaLibraryEmpty: Bool {
        get {
            var query = MPMediaQuery.songsQuery()
            return query.items.count == 0
        }
    }
    
    init() {
    }
    
    class var sharedSession : MediaSession {
        return _sharedSession
    }
    
    // Sync unscrobbled songs
    
    func syncUnscrobbledSongs() {
        LastFm.sharedInstance().apiKey = "d55a72556285ca314e7af8b0fb093e29"
        LastFm.sharedInstance().apiSecret = "affa81f90053b2114888298f3aeb27b9"
        
        if let username = NSUserDefaults.standardUserDefaults().objectForKey("LastFMUsername") as? String {
            if let password = NSUserDefaults.standardUserDefaults().objectForKey("LastFMPassword") as? String {
                LastFm.sharedInstance().getSessionForUser(username, password: password, successHandler: { (userData) -> Void in
                    LocalyticsSession.shared().tagEvent("Lastfm Login")
                    
                    let session = userData["key"] as! String
                    LastFm.sharedInstance().session = session
                    
                    LastFm.sharedInstance().getRecentTracksForUserOrNil(username, limit: 2, successHandler: { (tracks) -> Void in
                        
                        var t: LastFmTrack?
                        
                        for lastFMTrack in tracks as! [[NSObject : AnyObject]] {
                            var track = LastFmTrack(JSON: lastFMTrack)
                            if let date = track.date {
                                t = track
                                break
                            }
                        }
                        
                        if let track = t {
                            var unscrobbledItems = MediaSession.sharedSession.playedSongsAfterDate(track.date)
                            for item in unscrobbledItems as! [MPMediaItem] {
                                LastFm.sharedInstance().sendScrobbledTrack(item.title, byArtist: item.artist, onAlbum: item.albumTitle, withDuration: item.playbackDuration, atTimestamp: item.lastPlayedDate.timeIntervalSince1970, successHandler: { (results) -> Void in
                                    print(results)
                                    }, failureHandler: { (error) -> Void in
                                        print(error)
                                })
                            }
                        }
                        
                        
                        }, failureHandler: { (error) -> Void in
                            print(error)
                    })
                    
                    }, failureHandler: { (error) -> Void in
                        LocalyticsSession.shared().tagEvent("Failed Lastfm Login")
                })
            }
        }
    }
    
    // Playlists
    
    func fetchPlaylists(completion: (playlists: [AnyObject]) -> ()) {
        let playlistQuery = MPMediaQuery.playlistsQuery()
        completion(playlists: playlistQuery.collections)
    }
    
    // Artists
    
    func fetchArtists(completion: (results: [AnyObject]) -> ()) {
        artistsQuery = MPMediaQuery.artistsQuery()
        self.removeAllPredicatesFromQuery(artistsQuery)
        artistsQuery.addFilterPredicate(MPMediaPropertyPredicate(value: MPMediaType.Music.rawValue,
            forProperty: MPMediaItemPropertyMediaType,
            comparisonType: .EqualTo))
        completion(results: artistsQuery.items)
    }

    func fetchImageForArtist(#artist: Artist, completion: (image: UIImage?) -> ()) {
        
        self.removeAllPredicatesFromQuery(artistsQuery)
        
        artistsQuery.addFilterPredicate(MPMediaPropertyPredicate(value: artist.name,
            forProperty: MPMediaItemPropertyArtist,
            comparisonType: .Contains))
        
        var image: UIImage?
        if artistsQuery.items.count > 0 {
            for item in artistsQuery.items as! [MPMediaItem] {
                if let artwork = item.artwork {
                    if let artistImage = artwork.imageWithSize(CGSizeMake(200, 200)) {
                        image = artistImage
                        break
                    }
                }
            }
        }
        
        completion(image: image)
    }
    
    func fetchArtistCollectionForArtist(#artist: String, completion: (collection: MPMediaItemCollection) -> ()) {
        self.removeAllPredicatesFromQuery(artistsQuery)
        
        artistsQuery.addFilterPredicate(MPMediaPropertyPredicate(value: artist,
            forProperty: MPMediaItemPropertyArtist,
            comparisonType: .EqualTo))
        
        completion(collection: MPMediaItemCollection(items: artistsQuery.items))
    }
    
    // MARK: Albums
    
    func fetchAlbumCollectionForAlbum(#album: Album, completion: (collection: MPMediaItemCollection) -> ()) {
        self.removeAllPredicatesFromQuery(albumsQuery)
        
        albumsQuery.addFilterPredicate(MPMediaPropertyPredicate(value: album.title,
            forProperty: MPMediaItemPropertyAlbumTitle,
            comparisonType: .EqualTo))
        
        completion(collection: MPMediaItemCollection(items: albumsQuery.items))
    }
    
    func fetchAlbumsForArtist(#artist: Artist, completion: (results: [AnyObject]) -> ()) {
        self.removeAllPredicatesFromQuery(albumsQuery)
        albumsQuery.addFilterPredicate(MPMediaPropertyPredicate(value: artist.persistentID, forProperty: MPMediaItemPropertyArtistPersistentID, comparisonType: .EqualTo))
        completion(results: albumsQuery.items)
    }
    
    func fetchImageForAlbum(#album: Album, completion: (image: UIImage?) -> ()) {
        
        self.removeAllPredicatesFromQuery(albumsQuery)
        
        albumsQuery.addFilterPredicate(MPMediaPropertyPredicate(value: album.title,
            forProperty: MPMediaItemPropertyAlbumTitle,
            comparisonType: .Contains))
        
        var image: UIImage?
        if albumsQuery.items.count > 0 {
            for item in albumsQuery.items as! [MPMediaItem] {
                if let artwork = item.artwork {
                    if let albumImage = artwork.imageWithSize(CGSizeMake(200, 200)) {
                        image = albumImage
                        break
                    }
                }
            }
        }
        
        completion(image: image)
    }
    
    // MARK: Songs
    
    func fetchSongsCollection(completion: (collection: MPMediaItemCollection) -> ()) {
        self.removeAllPredicatesFromQuery(self.songsQuery)
        completion(collection: MPMediaItemCollection(items: self.songsQuery.items))
    }
    
    func fetchItemForSong(song: Song, completion: (item: MPMediaItem?) -> ()) {
        self.removeAllPredicatesFromQuery(songsQuery)
        
        let predicate = MPMediaPropertyPredicate(value: song.persistentID,
            forProperty: MPMediaItemPropertyPersistentID,
            comparisonType: .EqualTo)
        
        songsQuery.addFilterPredicate(predicate)
        
        if songsQuery.items.count > 0 {
            completion(item: songsQuery.items[0] as? MPMediaItem)
        } else {
            completion(item: nil)
        }
    }
    
    func fetchImageForSong(#song: Song, completion: (image: UIImage?) -> ()) {
        
        self.removeAllPredicatesFromQuery(songsQuery)
        
        songsQuery.addFilterPredicate(MPMediaPropertyPredicate(value: song.persistentID,
            forProperty: MPMediaItemPropertyPersistentID,
            comparisonType: .EqualTo))
        
        var image: UIImage?
        if songsQuery.items.count > 0 {
            let item = songsQuery.items[0] as! MPMediaItem
            if let artwork = item.artwork {
                if let songImage = artwork.imageWithSize(CGSizeMake(50, 50)) {
                    image = songImage
                }
            }
        }
        
        completion(image: image)
    }
    
    func fetchImageWithSongData(#song: NSDictionary, completion: (image: UIImage?) -> ()) {
        
        self.removeAllPredicatesFromQuery(songsQuery)
        
        let persistentID = song.objectForKey("persistentID") as! NSNumber
        
        songsQuery.addFilterPredicate(MPMediaPropertyPredicate(value: persistentID,
            forProperty: MPMediaItemPropertyPersistentID,
            comparisonType: .EqualTo))
        
        var image: UIImage?
        if songsQuery.items.count > 0 {
            let item = songsQuery.items[0] as! MPMediaItem
            if let artwork = item.artwork {
                if let songImage = artwork.imageWithSize(CGSizeMake(50, 50)) {
                    image = songImage
                }
            }
        }
        
        completion(image: image)
    }
    
    func fetchSongs(completion: (results: [AnyObject]) -> ()) {
        self.removeAllPredicatesFromQuery(songsQuery)
        completion(results: songsQuery.items)
    }
    
    // Helpers
    
    func removeAllPredicatesFromQuery(query: MPMediaQuery) {
        query.filterPredicates = nil
    }
    
    // MARK: OLD
    
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
    
    func playedSongsAfterDate(date: NSDate) -> [AnyObject] {
        var songsQuery = MPMediaQuery.songsQuery()
        songsQuery.filterPredicates = nil
        var items = songsQuery.items.filter { (item) -> Bool in
            if let playedDate = item.lastPlayedDate {
                if playedDate != nil {
                    return date.compare(playedDate) == .OrderedAscending
                }
            }
            
            return false
        }
        
        return items
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
        
        return artistsSections as [AnyObject]
    }
    
    func playlistSongsForPlaylist(playlist: Playlist) -> MPMediaQuery {
        println(playlist.persistentID!.toInt())
        let predicate = MPMediaPropertyPredicate(value: playlist.persistentID!.toInt(),
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
        
        for playlistSong in songs as! [PlaylistSong] {
            var query = MPMediaQuery.songsQuery()
            println(playlistSong.song.persistentID)
            let predicate = MPMediaPropertyPredicate(value: playlistSong.song.persistentID,
                forProperty: MPMediaItemPropertyPersistentID,
                comparisonType: .EqualTo)
            query.addFilterPredicate(predicate)
            items.addObjectsFromArray(query.items)
        }
        
        println(items)
        
        return MPMediaItemCollection(items: items as [AnyObject])
    }
}
