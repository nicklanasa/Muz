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
    
    func fetchImageForArtist(artist: Artist, completion: @escaping (_ image: UIImage?, _ error: NSError?) -> ()) {
        MediaSession.sharedSession.fetchImageForArtist(artist: artist) { (image) -> () in
            completion(image, nil)
        }
    }
    
    func syncArtists(_ completion: @escaping (_ addedItems: [AnyObject], _ error: NSErrorPointer) -> (), progress: @escaping (_ addedItems: [AnyObject], _ total: Int) -> ()) {
        self.datastore.resetLibrary { (error) -> () in
            MediaSession.sharedSession.fetchArtists { (results) -> () in
                self.datastore.addArtists(results! as NSArray, completion: { (addedItems, error) -> () in
                    completion(addedItems, error)
                    }, progress: { (addedItems, total) -> () in
                        progress(addedItems, total)
                })
            }
        }
    }
    
    func fetchImageForAlbum(album: Album, completion: @escaping (_ image: UIImage?, _ error: NSError?) -> ()) {
        MediaSession.sharedSession.fetchImageForAlbum(album: album) { (image) -> () in
            completion(image, nil)
        }
    }
    
    func fetchCollectionForAlbum(album: Album, completion: @escaping (_ collection: MPMediaItemCollection?, _ error: NSErrorPointer) -> ()) {
        MediaSession.sharedSession.fetchAlbumCollectionForAlbum(album: album) { (collection) -> () in
            completion(collection, nil)
        }
    }
    
    func fetchCollectionForArtist(artist: String, completion: @escaping (_ collection: MPMediaItemCollection?, _ error: NSErrorPointer) -> ()) {
        MediaSession.sharedSession.fetchArtistCollectionForArtist(artist: artist) { (collection) -> () in
            completion(collection, nil)
        }
    }
    
    func syncAlbumsForArtist(artist: Artist, completion: @escaping (_ addedItems: [AnyObject], _ error: NSErrorPointer) -> ()) {
        MediaSession.sharedSession.fetchAlbumsForArtist(artist: artist) { (results) -> () in
            self.datastore.addAlbumsForArtist(artist: artist, albums: results! as NSArray, completion: { (addedItems, error) -> () in
                completion(addedItems, error)
            })
        }
    }
    
    func fetchImageForSong(song: Song, completion: @escaping (_ image: UIImage?, _ error: NSError?) -> ()) {
        MediaSession.sharedSession.fetchImageForSong(song: song) { (image) -> () in
            completion(image, nil)
        }
    }
    
    func fetchImageWithSongData(song: NSDictionary, completion: @escaping (_ image: UIImage?, _ error: NSError?) -> ()) {
        MediaSession.sharedSession.fetchImageWithSongData(song: song) { (image) -> () in
            completion(image, nil)
        }
    }
    
    func fetchItemForSong(_ song: Song, completion: @escaping (_ item: MPMediaItem?) -> ())  {
        return MediaSession.sharedSession.fetchItemForSong(song, completion: { (item) -> () in
            completion(item)
        })
    }
    
    func syncSongs(_ completion: @escaping (_ addedItems: [AnyObject], _ error: NSErrorPointer) -> ()) {
        MediaSession.sharedSession.fetchSongs { (results) -> () in
            self.datastore.addSongs(results as! NSArray, completion: { (addedItems, error) -> () in
                completion(addedItems: addedItems, error: error)
            })
        }
    }
    
    func fetchSongsCollection(_ completion: @escaping (_ collection: MPMediaItemCollection?, _ error: NSErrorPointer) -> ()) {
        MediaSession.sharedSession.fetchSongsCollection { (collection) -> () in
            completion(collection, nil)
        }
    }

    func syncPlaylists(_ completion: @escaping (_ addedItems: [AnyObject]?, _ error: NSErrorPointer) -> ()) {
        MediaSession.sharedSession.fetchPlaylists { (playlists) -> () in
            self.datastore.addPlaylists(playlists, completion: { (addedPlaylists) -> () in
                completion(addedPlaylists, nil)
            })
        }
    }
}
