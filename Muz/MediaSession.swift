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

class MediaSession {
    
    let dataManager = DataManager.manager
    var artistsQuery = MPMediaQuery.artistsQuery()
    var albumsQuery = MPMediaQuery.albumsQuery()
    var songsQuery = MPMediaQuery.songsQuery()
    
    var currentQueueCollection: MPMediaItemCollection?
    
    var isMediaLibraryEmpty: Bool {
        get {
            let query = MPMediaQuery.songsQuery()
            return query.items?.count == 0
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
                    
                    let session = userData["key"] as! String
                    LastFm.sharedInstance().session = session
                    
                    LastFm.sharedInstance().getRecentTracksForUserOrNil(username, limit: 2, successHandler: { (tracks) -> Void in
                        
                        var t: LastFmTrack?
                        
                        for lastFMTrack in tracks as! [[NSObject : AnyObject]] {
                            let track = LastFmTrack(JSON: lastFMTrack)
                            if let _ = track.date {
                                t = track
                                break
                            }
                        }
                        
                        if let track = t {
                            let unscrobbledItems = MediaSession.sharedSession.playedSongsAfterDate(track.date)
                            if unscrobbledItems?.count > 0 {
                                LastFm.sharedInstance().scrobbleTracks(unscrobbledItems!, completion: { (results, error) -> () in
                                    if error != nil {
                                        UIAlertView(title: "Error!",
                                            message: error!.localizedDescription,
                                            delegate: self,
                                            cancelButtonTitle: "Ok").show()
                                    }
                                })
                            }
                        }
                        
                        
                        }, failureHandler: { (error) -> Void in
                            print(error, terminator: "")
                    })
                    
                    }, failureHandler: { (error) -> Void in
                })
            }
        }
    }
    
    // Playlists
    
    func fetchPlaylists(completion: (playlists: [AnyObject]?) -> ()) {
        let playlistQuery = MPMediaQuery.playlistsQuery()
        completion(playlists: playlistQuery.collections)
    }
    
    // Artists
    
    func fetchArtists(completion: (results: [AnyObject]?) -> ()) {
        artistsQuery = MPMediaQuery.artistsQuery()
        self.removeAllPredicatesFromQuery(artistsQuery)
        artistsQuery.addFilterPredicate(MPMediaPropertyPredicate(value: MPMediaType.Music.rawValue,
            forProperty: MPMediaItemPropertyMediaType,
            comparisonType: .EqualTo))
        completion(results: artistsQuery.items)
    }

    func fetchImageForArtist(artist artist: Artist, completion: (image: UIImage?) -> ()) {
        
        self.removeAllPredicatesFromQuery(artistsQuery)
        
        artistsQuery.addFilterPredicate(MPMediaPropertyPredicate(value: artist.name,
            forProperty: MPMediaItemPropertyArtist,
            comparisonType: .Contains))
        
        var image: UIImage?
        if artistsQuery.items?.count > 0 {
            for item in artistsQuery.items! {
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
    
    func fetchArtistCollectionForArtist(artist artist: String, completion: (collection: MPMediaItemCollection?) -> ()) {
        self.removeAllPredicatesFromQuery(artistsQuery)
        
        artistsQuery.addFilterPredicate(MPMediaPropertyPredicate(value: artist,
            forProperty: MPMediaItemPropertyArtist,
            comparisonType: .EqualTo))
        
        var collection: MPMediaItemCollection?
        
        if let items = artistsQuery.items {
            collection = MPMediaItemCollection(items: items)
        }
        
        completion(collection: collection)
    }
    
    // MARK: Albums
    
    func fetchAlbumCollectionForAlbum(album album: Album, completion: (collection: MPMediaItemCollection?) -> ()) {
        self.removeAllPredicatesFromQuery(albumsQuery)
        
        albumsQuery.addFilterPredicate(MPMediaPropertyPredicate(value: album.title,
            forProperty: MPMediaItemPropertyAlbumTitle,
            comparisonType: .EqualTo))
        
        var collection: MPMediaItemCollection?
        
        if let items = albumsQuery.items {
            collection = MPMediaItemCollection(items: items)
        }
        
        completion(collection: collection)
    }
    
    func fetchAlbumsForArtist(artist artist: Artist, completion: (results: [AnyObject]?) -> ()) {
        self.removeAllPredicatesFromQuery(albumsQuery)
        albumsQuery.addFilterPredicate(MPMediaPropertyPredicate(value: artist.persistentID, forProperty: MPMediaItemPropertyArtistPersistentID, comparisonType: .EqualTo))
        completion(results: albumsQuery.items)
    }
    
    func fetchImageForAlbum(album album: Album, completion: (image: UIImage?) -> ()) {
        
        self.removeAllPredicatesFromQuery(albumsQuery)
        
        albumsQuery.addFilterPredicate(MPMediaPropertyPredicate(value: album.title,
            forProperty: MPMediaItemPropertyAlbumTitle,
            comparisonType: .Contains))
        
        var image: UIImage?
        if albumsQuery.items?.count > 0 {
            for item in albumsQuery.items! {
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
    
    func fetchSongsCollection(completion: (collection: MPMediaItemCollection?) -> ()) {
        self.removeAllPredicatesFromQuery(self.songsQuery)
    
        var collection: MPMediaItemCollection?
        
        if let items = self.songsQuery.items {
            collection = MPMediaItemCollection(items: items)
        }
        
        completion(collection: collection)
    }
    
    func fetchItemForSong(song: Song, completion: (item: MPMediaItem?) -> ()) {
        self.removeAllPredicatesFromQuery(songsQuery)
        
        let predicate = MPMediaPropertyPredicate(value: song.persistentID,
            forProperty: MPMediaItemPropertyPersistentID,
            comparisonType: .EqualTo)
        
        songsQuery.addFilterPredicate(predicate)
        
        if songsQuery.items?.count > 0 {
            completion(item: songsQuery.items![0])
        } else {
            completion(item: nil)
        }
    }
    
    func fetchImageForSong(song song: Song, completion: (image: UIImage?) -> ()) {
        
        self.removeAllPredicatesFromQuery(songsQuery)
        
        songsQuery.addFilterPredicate(MPMediaPropertyPredicate(value: song.persistentID,
            forProperty: MPMediaItemPropertyPersistentID,
            comparisonType: .EqualTo))
        
        var image: UIImage?
        if songsQuery.items?.count > 0 {
            let item = songsQuery.items![0]
            if let artwork = item.artwork {
                if let songImage = artwork.imageWithSize(CGSizeMake(50, 50)) {
                    image = songImage
                }
            }
        }
        
        completion(image: image)
    }
    
    func fetchImageWithSongData(song song: NSDictionary, completion: (image: UIImage?) -> ()) {
        
        self.removeAllPredicatesFromQuery(songsQuery)
        
        let persistentID = song.objectForKey("persistentID") as! NSNumber
        
        songsQuery.addFilterPredicate(MPMediaPropertyPredicate(value: persistentID,
            forProperty: MPMediaItemPropertyPersistentID,
            comparisonType: .EqualTo))
        
        var image: UIImage?
        if songsQuery.items?.count > 0 {
            let item = songsQuery.items![0]
            if let artwork = item.artwork {
                if let songImage = artwork.imageWithSize(CGSizeMake(50, 50)) {
                    image = songImage
                }
            }
        }
        
        completion(image: image)
    }
    
    func fetchSongs(completion: (results: [AnyObject]?) -> ()) {
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
    
    func songsQueryWithPredicate(predicate: MPMediaPropertyPredicate?) -> MPMediaQuery {
        let songsQuery = MPMediaQuery.songsQuery()
        
        if let p = predicate {
            songsQuery.addFilterPredicate(p)
        }
        
        return songsQuery
    }
    
    func playedSongsAfterDate(date: NSDate) -> [AnyObject]? {
        let songsQuery = MPMediaQuery.songsQuery()
        songsQuery.filterPredicates = nil
        let items = songsQuery.items?.filter { (item) -> Bool in
            if let playedDate = item.lastPlayedDate {
                return date.compare(playedDate) == .OrderedAscending
            }
            
            return false
        }
        
        return items
    }
    
    func artistsSectionIndexTitles(artistsQuery: MPMediaQuery) -> [AnyObject] {
        let artistsSections = NSMutableArray()
        if let sections = artistsQuery.collectionSections {
            for section in sections {
                artistsSections.addObject(section.title)
            }
        }
        
        return artistsSections as [AnyObject]
    }
    
    func playlistSongsForPlaylist(playlist: Playlist) -> MPMediaQuery {
        print(Int(playlist.persistentID!))
        let predicate = MPMediaPropertyPredicate(value: Int(playlist.persistentID!),
            forProperty: MPMediaPlaylistPropertyPersistentID,
            comparisonType: .EqualTo)
        let playlistSongsQuery = MPMediaQuery.playlistsQuery()
        playlistSongsQuery.addFilterPredicate(predicate)
        return playlistSongsQuery
    }
    
    func collectionWithPlaylistSongs(songs: [AnyObject]) -> MPMediaItemCollection? {
        var items = [MPMediaItem]()
        
        for playlistSong in songs as! [PlaylistSong] {
            let query = MPMediaQuery.songsQuery()
            print(playlistSong.song.persistentID)
            let predicate = MPMediaPropertyPredicate(value: playlistSong.song.persistentID,
                forProperty: MPMediaItemPropertyPersistentID,
                comparisonType: .EqualTo)
            query.addFilterPredicate(predicate)
            
            if let playlistItems = query.items {
                items.appendContentsOf(playlistItems)
            }
        }
        
        return MPMediaItemCollection(items: items)
    }
}
