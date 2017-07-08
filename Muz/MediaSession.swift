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
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


let _sharedSession = MediaSession()

var CurrentQueueItems: MPMediaItemCollection!

class MediaSession {
    
    let dataManager = DataManager.manager
    var artistsQuery = MPMediaQuery.artists()
    var albumsQuery = MPMediaQuery.albums()
    var songsQuery = MPMediaQuery.songs()
    
    var currentQueueCollection: MPMediaItemCollection?
    
    var isMediaLibraryEmpty: Bool {
        get {
            let query = MPMediaQuery.songs()
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
        
        if let username = UserDefaults.standard.object(forKey: "LastFMUsername") as? String {
            if let password = UserDefaults.standard.object(forKey: "LastFMPassword") as? String {
                LastFm.sharedInstance().getSessionForUser(username, password: password, successHandler: { (userData) -> Void in
                    
                    let session = userData?["key"] as! String
                    LastFm.sharedInstance().session = session
                    
                    LastFm.sharedInstance().getRecentTracks(forUserOrNil: username, limit: 2, successHandler: { (tracks) -> Void in
                        
                        var t: LastFmTrack?
                        
                        for lastFMTrack in tracks as! [[AnyHashable: Any]] {
                            let track = LastFmTrack(json: lastFMTrack)
                            if let _ = track?.date {
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
    
    func fetchPlaylists(_ completion: (_ playlists: [AnyObject]?) -> ()) {
        let playlistQuery = MPMediaQuery.playlists()
        completion(playlistQuery.collections)
    }
    
    // Artists
    
    func fetchArtists(_ completion: (_ results: [AnyObject]?) -> ()) {
        artistsQuery = MPMediaQuery.artists()
        self.removeAllPredicatesFromQuery(artistsQuery)
        artistsQuery.addFilterPredicate(MPMediaPropertyPredicate(value: MPMediaType.music.rawValue,
            forProperty: MPMediaItemPropertyMediaType,
            comparisonType: .equalTo))
        completion(artistsQuery.items)
    }

    func fetchImageForArtist(artist: Artist, completion: (_ image: UIImage?) -> ()) {
        
        self.removeAllPredicatesFromQuery(artistsQuery)
        
        artistsQuery.addFilterPredicate(MPMediaPropertyPredicate(value: artist.name,
            forProperty: MPMediaItemPropertyArtist,
            comparisonType: .contains))
        
        var image: UIImage?
        if artistsQuery.items?.count > 0 {
            for item in artistsQuery.items! {
                if let artwork = item.artwork {
                    if let artistImage = artwork.image(at: CGSize(width: 200, height: 200)) {
                        image = artistImage
                        break
                    }
                }
            }
        }
        
        completion(image)
    }
    
    func fetchArtistCollectionForArtist(artist: String, completion: (_ collection: MPMediaItemCollection?) -> ()) {
        self.removeAllPredicatesFromQuery(artistsQuery)
        
        artistsQuery.addFilterPredicate(MPMediaPropertyPredicate(value: artist,
            forProperty: MPMediaItemPropertyArtist,
            comparisonType: .equalTo))
        
        var collection: MPMediaItemCollection?
        
        if let items = artistsQuery.items {
            collection = MPMediaItemCollection(items: items)
        }
        
        completion(collection)
    }
    
    // MARK: Albums
    
    func fetchAlbumCollectionForAlbum(album: Album, completion: (_ collection: MPMediaItemCollection?) -> ()) {
        self.removeAllPredicatesFromQuery(albumsQuery)
        
        albumsQuery.addFilterPredicate(MPMediaPropertyPredicate(value: album.title,
            forProperty: MPMediaItemPropertyAlbumTitle,
            comparisonType: .equalTo))
        
        var collection: MPMediaItemCollection?
        
        if let items = albumsQuery.items {
            collection = MPMediaItemCollection(items: items)
        }
        
        completion(collection)
    }
    
    func fetchAlbumsForArtist(artist: Artist, completion: (_ results: [AnyObject]?) -> ()) {
        self.removeAllPredicatesFromQuery(albumsQuery)
        albumsQuery.addFilterPredicate(MPMediaPropertyPredicate(value: artist.persistentID, forProperty: MPMediaItemPropertyArtistPersistentID, comparisonType: .equalTo))
        completion(albumsQuery.items)
    }
    
    func fetchImageForAlbum(album: Album, completion: (_ image: UIImage?) -> ()) {
        
        self.removeAllPredicatesFromQuery(albumsQuery)
        
        albumsQuery.addFilterPredicate(MPMediaPropertyPredicate(value: album.title,
            forProperty: MPMediaItemPropertyAlbumTitle,
            comparisonType: .contains))
        
        var image: UIImage?
        if albumsQuery.items?.count > 0 {
            for item in albumsQuery.items! {
                if let artwork = item.artwork {
                    if let albumImage = artwork.image(at: CGSize(width: 200, height: 200)) {
                        image = albumImage
                        break
                    }
                }
            }
        }
        
        completion(image)
    }
    
    // MARK: Songs
    
    func fetchSongsCollection(_ completion: (_ collection: MPMediaItemCollection?) -> ()) {
        self.removeAllPredicatesFromQuery(self.songsQuery)
    
        var collection: MPMediaItemCollection?
        
        if let items = self.songsQuery.items {
            collection = MPMediaItemCollection(items: items)
        }
        
        completion(collection)
    }
    
    func fetchItemForSong(_ song: Song, completion: (_ item: MPMediaItem?) -> ()) {
        self.removeAllPredicatesFromQuery(songsQuery)
        
        let predicate = MPMediaPropertyPredicate(value: song.persistentID,
            forProperty: MPMediaItemPropertyPersistentID,
            comparisonType: .equalTo)
        
        songsQuery.addFilterPredicate(predicate)
        
        if songsQuery.items?.count > 0 {
            completion(songsQuery.items![0])
        } else {
            completion(nil)
        }
    }
    
    func fetchImageForSong(song: Song, completion: (_ image: UIImage?) -> ()) {
        
        self.removeAllPredicatesFromQuery(songsQuery)
        
        songsQuery.addFilterPredicate(MPMediaPropertyPredicate(value: song.persistentID,
            forProperty: MPMediaItemPropertyPersistentID,
            comparisonType: .equalTo))
        
        var image: UIImage?
        if songsQuery.items?.count > 0 {
            let item = songsQuery.items![0]
            if let artwork = item.artwork {
                if let songImage = artwork.image(at: CGSize(width: 50, height: 50)) {
                    image = songImage
                }
            }
        }
        
        completion(image)
    }
    
    func fetchImageWithSongData(song: NSDictionary, completion: (_ image: UIImage?) -> ()) {
        
        self.removeAllPredicatesFromQuery(songsQuery)
        
        let persistentID = song.object(forKey: "persistentID") as! NSNumber
        
        songsQuery.addFilterPredicate(MPMediaPropertyPredicate(value: persistentID,
            forProperty: MPMediaItemPropertyPersistentID,
            comparisonType: .equalTo))
        
        var image: UIImage?
        if songsQuery.items?.count > 0 {
            let item = songsQuery.items![0]
            if let artwork = item.artwork {
                if let songImage = artwork.image(at: CGSize(width: 50, height: 50)) {
                    image = songImage
                }
            }
        }
        
        completion(image)
    }
    
    func fetchSongs(_ completion: (_ results: [AnyObject]?) -> ()) {
        self.removeAllPredicatesFromQuery(songsQuery)
        completion(songsQuery.items)
    }
    
    // Helpers
    
    func removeAllPredicatesFromQuery(_ query: MPMediaQuery) {
        query.filterPredicates = nil
    }
    
    // MARK: OLD
    
    func artistsCollectionWithQuery(_ artistsQuery: MPMediaQuery) -> [AnyObject]? {
        return artistsQuery.collections
    }
    
    func artistsQueryWithFilters(_ filters: [MPMediaPredicate]?) -> MPMediaQuery {
        let artistsQuery = MPMediaQuery.artists()
        
        if let predicates = filters {
            for predicate in predicates {
                artistsQuery.addFilterPredicate(predicate)
            }
        }
        
        return artistsQuery
    }
    
    func songsQueryWithPredicate(_ predicate: MPMediaPropertyPredicate?) -> MPMediaQuery {
        let songsQuery = MPMediaQuery.songs()
        
        if let p = predicate {
            songsQuery.addFilterPredicate(p)
        }
        
        return songsQuery
    }
    
    func playedSongsAfterDate(_ date: Date) -> [AnyObject]? {
        let songsQuery = MPMediaQuery.songs()
        songsQuery.filterPredicates = nil
        let items = songsQuery.items?.filter { (item) -> Bool in
            if let playedDate = item.lastPlayedDate {
                return date.compare(playedDate) == .orderedAscending
            }
            
            return false
        }
        
        return items
    }
    
    func artistsSectionIndexTitles(_ artistsQuery: MPMediaQuery) -> [AnyObject] {
        let artistsSections = NSMutableArray()
        if let sections = artistsQuery.collectionSections {
            for section in sections {
                artistsSections.add(section.title)
            }
        }
        
        return artistsSections as [AnyObject]
    }
    
    func playlistSongsForPlaylist(_ playlist: Playlist) -> MPMediaQuery {
        print(Int(playlist.persistentID!))
        let predicate = MPMediaPropertyPredicate(value: Int(playlist.persistentID!),
            forProperty: MPMediaPlaylistPropertyPersistentID,
            comparisonType: .equalTo)
        let playlistSongsQuery = MPMediaQuery.playlists()
        playlistSongsQuery.addFilterPredicate(predicate)
        return playlistSongsQuery
    }
    
    func collectionWithPlaylistSongs(_ songs: [AnyObject]) -> MPMediaItemCollection? {
        var items = [MPMediaItem]()
        
        for playlistSong in songs as! [PlaylistSong] {
            let query = MPMediaQuery.songs()
            print(playlistSong.song.persistentID)
            let predicate = MPMediaPropertyPredicate(value: playlistSong.song.persistentID,
                forProperty: MPMediaItemPropertyPersistentID,
                comparisonType: .equalTo)
            query.addFilterPredicate(predicate)
            
            if let playlistItems = query.items {
                items.append(contentsOf: playlistItems)
            }
        }
        
        return MPMediaItemCollection(items: items)
    }
}
