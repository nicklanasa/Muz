//
//  DataManager.swift
//  FartyPants
//
//  Created by Nick Lanasa on 11/15/14.
//  Copyright (c) 2014 Nytek Productions. All rights reserved.
//

import Foundation
import CoreData
import MediaPlayer

let _manager = DataManager()

class DataManager {
    
    var datastore: Datastore!
    
    class var manager : DataManager {
        return _manager
    }
    
    init() {
        datastore = Datastore(storeName: "Muz 2")
    }
    
    func fetchImageForArtist(#artist: Artist, completion: (image: UIImage?, error: NSError?) -> ()) {
        MediaSession.sharedSession.fetchImageForArtist(artist: artist) { (image) -> () in
            completion(image: image, error: nil)
        }
    }
    
    func syncArtists(completion: (addedItems: [AnyObject], error: NSErrorPointer) -> (),
        progress: (addedItems: [AnyObject], total: Int) -> ()) {
        MediaSession.sharedSession.fetchArtists { (results) -> () in
            self.datastore.addArtists(results, completion: { (addedItems, error) -> () in
                completion(addedItems: addedItems, error: error)
            }, progress: { (addedItems, total) -> () in
                progress(addedItems: addedItems, total: total)
            })
        }
    }
    
    func fetchImageForAlbum(#album: Album, completion: (image: UIImage?, error: NSError?) -> ()) {
        MediaSession.sharedSession.fetchImageForAlbum(album: album) { (image) -> () in
            completion(image: image, error: nil)
        }
    }
    
    func fetchCollectionForAlbum(#album: Album, completion: (collection: MPMediaItemCollection, error: NSErrorPointer) -> ()) {
        MediaSession.sharedSession.fetchAlbumCollectionForAlbum(album: album) { (collection) -> () in
            completion(collection: collection, error: nil)
        }
    }
    
    func fetchCollectionForArtist(#artist: String, completion: (collection: MPMediaItemCollection, error: NSErrorPointer) -> ()) {
        MediaSession.sharedSession.fetchArtistCollectionForArtist(artist: artist) { (collection) -> () in
            completion(collection: collection, error: nil)
        }
    }
    
    func syncAlbumsForArtist(#artist: Artist, completion: (addedItems: [AnyObject], error: NSErrorPointer) -> ()) {
        MediaSession.sharedSession.fetchAlbumsForArtist(artist: artist) { (results) -> () in
            self.datastore.addAlbumsForArtist(artist: artist, albums: results, completion: { (addedItems, error) -> () in
                completion(addedItems: addedItems, error: error)
            })
        }
    }
    
    func fetchImageForSong(#song: Song, completion: (image: UIImage?, error: NSError?) -> ()) {
        MediaSession.sharedSession.fetchImageForSong(song: song) { (image) -> () in
            completion(image: image, error: nil)
        }
    }
    
    func fetchImageWithSongData(#song: NSDictionary, completion: (image: UIImage?, error: NSError?) -> ()) {
        MediaSession.sharedSession.fetchImageWithSongData(song: song) { (image) -> () in
            completion(image: image, error: nil)
        }
    }
    
    func fetchItemForSong(#song: Song, completion: (item: MPMediaItem?) -> ())  {
        return MediaSession.sharedSession.fetchItemForSong(song, completion: { (item) -> () in
            completion(item: item)
        })
    }
    
    func syncSongs(completion: (addedItems: [AnyObject], error: NSErrorPointer) -> ()) {
        MediaSession.sharedSession.fetchSongs { (results) -> () in
            self.datastore.addSongs(results, completion: { (addedItems, error) -> () in
                completion(addedItems: addedItems, error: error)
            })
        }
    }
    
    func fetchSongsCollection(completion: (collection: MPMediaItemCollection, error: NSErrorPointer) -> ()) {
        MediaSession.sharedSession.fetchSongsCollection { (collection) -> () in
            completion(collection: collection, error: nil)
        }
    }

    func syncPlaylists(completion: (addedItems: [AnyObject]?, error: NSErrorPointer) -> ()) {
        MediaSession.sharedSession.fetchPlaylists { (playlists) -> () in
            self.datastore.addPlaylists(playlists, completion: { (addedPlaylists) -> () in
                completion(addedItems: addedPlaylists, error: nil)
            })
        }
    }
}
