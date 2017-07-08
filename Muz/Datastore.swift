//
//  Datastore.swift
//  FartyPants
//
//  Created by Nick Lanasa on 11/15/14.
//  Copyright (c) 2014 Nytek Productions. All rights reserved.
//

import Foundation
import UIKit
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

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func >= <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l >= r
  default:
    return !(lhs < rhs)
  }
}


let ArtistsCacheName = "artists"
let PlaylistsCacheName = "playlists"

class Datastore {
    
    let storeName: String
    
    var managedObjectModel: NSManagedObjectModel!
    var saveContext: NSManagedObjectContext!
    var workerContext: NSManagedObjectContext!
    var mainQueueContext: NSManagedObjectContext!
    var persistentStoreCoordinator: NSPersistentStoreCoordinator!
    
    init(storeName: String) {
        self.storeName = storeName
        configure()
    }
    
    fileprivate func configure() {
        let modelURL = Bundle.main.url(forResource: "Muz", withExtension: "momd")
        self.managedObjectModel = NSManagedObjectModel(contentsOf: modelURL!)!
        
        let storeUrlString = String(format: "%@.sqlite", self.storeName)
        let paths = FileManager.default.urls(for: FileManager.SearchPathDirectory.documentDirectory, in: FileManager.SearchPathDomainMask.userDomainMask)
        if let documentsURL = paths.last {
            let storeURL = documentsURL.appendingPathComponent(storeUrlString)
            self.persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
            
            do {
                try self.persistentStoreCoordinator.addPersistentStore(ofType: NSSQLiteStoreType,
                    configurationName: nil,
                    at: storeURL,
                    options: nil)
            } catch {}
            
            self.saveContext = NSManagedObjectContext(concurrencyType: NSManagedObjectContextConcurrencyType.privateQueueConcurrencyType)
            self.saveContext.persistentStoreCoordinator = self.persistentStoreCoordinator
            self.saveContext.undoManager = nil
            
            self.mainQueueContext = NSManagedObjectContext(concurrencyType: NSManagedObjectContextConcurrencyType.mainQueueConcurrencyType)
            self.mainQueueContext.undoManager = nil
            self.mainQueueContext.parent = self.saveContext
            
            self.workerContext = NSManagedObjectContext(concurrencyType: NSManagedObjectContextConcurrencyType.privateQueueConcurrencyType)
            self.workerContext.undoManager = nil
            self.workerContext.parent = self.mainQueueContext
            
        }
    }
    
    // MARK: Add songs
    
    func addSongs(_ songs: NSArray?, completion: @escaping (_ addedItems: [AnyObject], _ error: NSErrorPointer) -> ()) {
        let context = self.mainQueueContext
        context?.perform { () -> Void in
            let startTime = Date()
            
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Song")
            
            let addedSongs = NSMutableArray(capacity: songs?.count ?? 0)
            let existedSongs = NSMutableArray(capacity: songs?.count ?? 0)
            
            var count = 0
            
            for song in (songs as? [MPMediaItem])! {
                count += 1
                if let artist = song.artist, let title = song.title {
                    
                    let predicate = NSPredicate(format: "title = %@ AND artist = %@", title, artist)
                    request.fetchLimit = 1
                    request.predicate = predicate
                    let results: [AnyObject]?
                    do {
                        results = try context?.fetch(request)
                    } catch {
                        fatalError()
                    }
                    
                    var managedSong: Song!
                    if results?.count > 0 {
                        managedSong = results?[0] as! Song
                    } else {
                        managedSong = NSEntityDescription.insertNewObject(forEntityName: "Song",
                            into: context!) as! Song
                        managedSong.parseItem(song)
                    }
                    
                    addedSongs.add(managedSong)
                }
            }
            
            self.saveDatastoreWithCompletion({ (error) -> () in
                let endTime = Date()
                let executionTime = endTime.timeIntervalSince(startTime)
                NSLog("addSongs() - executionTime = %f\n addedSongs count: %d\n existedSongs count: %d", (executionTime * 1000), addedSongs.count, existedSongs.count);
                
                completion(addedSongs as [AnyObject], error)
            })
        }
    }
    
    fileprivate func dispatchAddBlock(_ dispatchBlock: @escaping () -> ()) -> () {
        DispatchQueue.main.async(execute: dispatchBlock)
    }
    
    
    func resetLibrary(_ completion: @escaping (_ error: NSErrorPointer) -> ()) {
        self.workerContext.perform { () -> Void in
            var error: NSError?
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Artist")
            let results: [AnyObject]?
            do {
                results = try self.workerContext.fetch(request)
            } catch let error1 as NSError {
                error = error1
                results = nil
            } catch {
                fatalError()
            }
            
            for artist in results as! [Artist] {
                
                for album in artist.albums.allObjects as! [Album] {
                    for song in album.songs.allObjects as! [Song] {
                        self.workerContext.delete(song)
                    }
                    
                    self.workerContext.delete(album)
                }
                
                self.workerContext.delete(artist)
            }
            
            completion(&error)
        }
    }
    
    /**
    Adds artists to the datastore.
    
    - parameter artists:    The artists you want to add.
    - parameter completion: The completion block called at the end of the execution.
    */
    func addArtists(_ artists: NSArray?, completion: @escaping (_ addedItems: [AnyObject], _ error: NSErrorPointer) -> (),
        progress: @escaping (_ addedItems: [AnyObject], _ total: Int) -> ())
    {
        let context = self.workerContext
        context?.perform { () -> Void in
           
            let startTime = Date()
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Artist")
            let addedArtists = NSMutableArray(capacity: artists?.count ?? 0)
            
            artists?.enumerateObjects({ (artist, idx, stop) -> Void in
                if let item = artist as? MPMediaItem {
                    
                    if let artistName = item.artist {
                        
                        let predicate = NSPredicate(format: "name = %@", artistName)
                        request.fetchLimit = 1
                        request.predicate = predicate
                        let results: [AnyObject]?
                        do {
                            results = try context?.fetch(request)
                        } catch {
                            fatalError()
                        }
                        
                        var managedArtist: Artist!
                        if results?.count > 0 {
                            managedArtist = results?[0] as! Artist
                        } else {
                            managedArtist = NSEntityDescription.insertNewObject(forEntityName: "Artist",
                                into: context!) as! Artist
                        }
                        
                        managedArtist.parseItem(item)
                        
                        // Add albums
                        self.addAlbumForItem(item: item, artist: managedArtist, context: context!)
                        
                        addedArtists.add(managedArtist)
                        
                        progress(addedArtists as [AnyObject], artists?.count ?? 0)
                    }
                }
            })

            self.saveDatastoreWithCompletion({ (error) -> () in
                let endTime = Date()
                let executionTime = endTime.timeIntervalSince(startTime)
                NSLog("addArtists() - executionTime = %f\n addedSongs count: %d\n existedSongs count: %d", (executionTime * 1000), addedArtists.count);

                completion(addedArtists as [AnyObject], error)
            })
        }
    }
    
    func addAlbumsForArtist(artist: Artist, albums: NSArray?, completion: @escaping (_ addedItems: [AnyObject], _ error: NSErrorPointer) -> ()) {
        self.workerContext.perform { () -> Void in
            
            let startTime = Date()
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Album")
            let addedAlbums = NSMutableArray(capacity: albums?.count ?? 0)
            
            albums?.enumerateObjects({ (album, idx, stop) -> Void in
                if let item = album as? MPMediaItem {
                    
                    if let title = item.albumTitle {
                        
                        let predicate = NSPredicate(format: "title = %@", title)
                        request.fetchLimit = 1
                        request.predicate = predicate
                        let results: [AnyObject]?
                        do {
                            results = try self.workerContext.fetch(request)
                        } catch {
                            fatalError()
                        }
                        
                        var managedAlbum: Album!
                        if results?.count > 0 {
                            managedAlbum = results?[0] as! Album
                        } else {
                            managedAlbum = NSEntityDescription.insertNewObject(forEntityName: "Album",
                                into: self.workerContext) as! Album
                            addedAlbums.add(managedAlbum)
                        }
                        
                        managedAlbum.parseItem(item)
                        self.addSongForItem(item: item, album: managedAlbum, context: self.workerContext)
                        
                        artist.addAlbum(managedAlbum)
                    }
                }

            })
            
            artist.modifiedDate = Date()
            
            self.saveDatastoreWithCompletion({ (error) -> () in
                let endTime = Date()
                let executionTime = endTime.timeIntervalSince(startTime)
                NSLog("addAlbums() - executionTime = %f\n addAlbums count: %d", (executionTime * 1000), addedAlbums.count);
                
                completion(addedAlbums as [AnyObject], error)
            })
        }

    }
    
    /**
    Add album for item.
    
    - parameter item: The item you want to use to add a new album from.
    
    - returns: The created/existing album or nil.
    */
    func addAlbumForItem(item: MPMediaItem, artist: Artist, context: NSManagedObjectContext) {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Album")
        
        let predicate = NSPredicate(format: "title = %@", item.albumTitle ?? "")
        request.fetchLimit = 1
        request.predicate = predicate
        let results: [AnyObject]?
        do {
            results = try context.fetch(request)
            var managedAlbum: Album!
            if results?.count > 0 {
                managedAlbum = results?[0] as! Album
            } else {
                managedAlbum = NSEntityDescription.insertNewObject(forEntityName: "Album",
                    into: context) as! Album
            }
            
            managedAlbum.parseItem(item)
            managedAlbum.artist = artist
            
            self.addSongForItem(item: item, album: managedAlbum, context: context)
        } catch { }
    }
    
    func artistForSong(song: Song) -> Artist? {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Artist")
        let predicate = NSPredicate(format: "name = %@", song.artist)
        request.fetchLimit = 1
        request.predicate = predicate
        let results: [AnyObject]?
        do {
            results = try self.workerContext.fetch(request)
            var managedArtist: Artist!
            if results?.count > 0 {
                managedArtist = results?[0] as! Artist
                return managedArtist
            } else {
                return nil
            }
        } catch {
            return nil
        }
    }
    
    func artistForSongData(song: NSDictionary) -> Artist? {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Artist")
        let predicate = NSPredicate(format: "name = %@", song.object(forKey: "artist") as! String)
        request.fetchLimit = 1
        request.predicate = predicate
        let results: [AnyObject]?
        do {
            results = try self.workerContext.fetch(request)
            var managedArtist: Artist!
            if results?.count > 0 {
                managedArtist = results?[0] as! Artist
                return managedArtist
            } else {
                return nil
            }
        } catch { return nil }
    }
    
    /**
    Adds a song to an album.
    
    - parameter item: The song you want to add.
    
    - returns: The added song.
    */
    func addSongForItem(item: MPMediaItem, album: Album, context: NSManagedObjectContext) {
        
        let managedSong = NSEntityDescription.insertNewObject(forEntityName: "Song",
            into: context) as! Song
        
        managedSong.parseItem(item)
        managedSong.album = album
    }
    
    func updateSong(song: Song, completion: @escaping () -> ()) {
        song.lastPlayedDate = Date()
        
        self.saveDatastoreWithCompletion({ (error) -> () in
            completion()
        })
    }
    
    func updatePlaylist(playlist: Playlist, completion: @escaping () -> ()) {
        playlist.modifiedDate = Date()
        
        self.saveDatastoreWithCompletion({ (error) -> () in
            print("Updated playlist with new modified date: \(playlist.modifiedDate)")
            completion()
        })
    }
    
    func addPlaylists(_ playlists: [AnyObject]?, completion: (_ addedPlaylists: [AnyObject]?) -> ()) {
        
        self.mainQueueContext.perform { () -> Void in
            
            let request = NSFetchRequest<NSFetchRequestResult>()
            request.entity = NSEntityDescription.entity(forEntityName: "Playlist",
                in: self.mainQueueContext)
            
            let results = try? self.mainQueueContext.fetch(request)
            
            if results?.count > 0 {
                for existingPlaylist in results as! [Playlist] {
                    if existingPlaylist.persistentID != "" {
                        self.mainQueueContext.delete(existingPlaylist)
                    }
                }
            }
            
            
            for playlist in playlists as! [MPMediaPlaylist] {
                self.createPlaylistWithPlaylist(playlist, context: self.mainQueueContext)
            }
            
            self.saveDatastoreWithCompletion({ (error) -> () in
                print("Saved datastore for playlists.")
            })
        }
    }

    func createPlaylistWithSimiliarArtists(_ artist: String!, artists: [AnyObject]!,
        fetchLimit: NSInteger,
        name: String!,
        playlistType: PlaylistType,
        completion: @escaping (_ addedSongs: [AnyObject]?) -> ()) {
        
        clearCache()
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Song")
    
        var predicates = [NSPredicate]()
        
        let artistPredicate = NSPredicate(format: "(artist contains[cd] %@)", artist)
        predicates.append(artistPredicate)
            
        for artist in artists as! [LastFmArtist] {
            print(artist.name)
            let predicate = NSPredicate(format: "(artist contains[cd] %@)", artist.name)
            predicates.append(predicate)
        }
        
        let compoundPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: predicates)
        request.predicate = compoundPredicate
        request.fetchLimit = fetchLimit
        
        let results: [AnyObject]?
        do {
            results = try self.workerContext.fetch(request)
            
            if results?.count > 0 {
                
                // Create smart playlist based on artists.
                let playlist = NSEntityDescription.insertNewObject(forEntityName: "Playlist",
                    into: self.workerContext) as! Playlist
                playlist.name = name
                playlist.playlistType = NSNumber(value: playlistType.rawValue as UInt)
                playlist.persistentID = ""
                playlist.modifiedDate = Date()
                
                // Create PlaySongs
                let playlistSongs = NSMutableSet()
                var order = 0
                
                for song in results as! [Song] {
                    let playlistSong = NSEntityDescription.insertNewObject(forEntityName: "PlaylistSong",
                        into: self.workerContext) as! PlaylistSong
                    
                    playlistSong.parseSong(song, playlist: playlist, order: order)
                    playlistSongs.add(playlistSong)
                    print("Created new playlist song with title: \(song.title)")
                    order += 1
                }
                
                playlist.playlistSongs = playlistSongs
            }
            
            self.saveDatastoreWithCompletion { (error) -> () in
                if results?.count > 0 {
                    completion(results)
                } else {
                    completion(nil)
                }
            }
        } catch { }
    }
    
    func createPlaylistWithArtist(_ artist: String!,
        name: String!,
        playlistType: PlaylistType,
        completion: @escaping (_ addedSongs: [AnyObject]?) -> ()) {
            
        clearCache()
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Song")
        
        let predicate = NSPredicate(format: "(artist contains[cd] %@)", artist)
        request.predicate = predicate
        
        let results: [AnyObject]?
        do {
            results = try self.mainQueueContext.fetch(request)
            if results?.count > 0 {
                
                // Create smart playlist based on artists.
                let playlist = NSEntityDescription.insertNewObject(forEntityName: "Playlist",
                    into: self.mainQueueContext) as! Playlist
                playlist.name = name
                playlist.playlistType = NSNumber(value: playlistType.rawValue as UInt)
                playlist.persistentID = ""
                playlist.modifiedDate = Date()
                
                // Create PlaySongs
                let playlistSongs = NSMutableSet()
                var order = 0
                
                for song in results as! [Song] {
                    let playlistSong = NSEntityDescription.insertNewObject(forEntityName: "PlaylistSong",
                        into: self.mainQueueContext) as! PlaylistSong
                    
                    playlistSong.parseSong(song, playlist: playlist, order: order)
                    playlistSongs.add(playlistSong)
                    print("Created new playlist song with title: \(song.title)")
                    order += 1
                }
                
                playlist.playlistSongs = playlistSongs
            }
            
            self.saveDatastoreWithCompletion { (error) -> () in
                if results?.count > 0 {
                    completion(results)
                } else {
                    completion(nil)
                }
            }
        } catch { completion(nil) }
    }
    
    // TODO: Change this to use worker context.
    func addArtistSongsToPlaylist(_ playlist: Playlist, artist: String!,
        completion: @escaping (_ addedSongs: [AnyObject]?) -> ()) {
            
        clearCache()
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Song")
        
        let predicate = NSPredicate(format: "(artist contains[cd] %@)", artist)
        request.predicate = predicate
        
        let results: [AnyObject]?
        do {
            results = try self.mainQueueContext.fetch(request)
            if results?.count > 0 {
                // Create PlaySongs
                let playlistSongs = NSMutableSet()
                var order = playlist.playlistSongs.count
                
                for song in results as! [Song] {
                    let playlistSong = NSEntityDescription.insertNewObject(forEntityName: "PlaylistSong",
                        into: self.mainQueueContext) as! PlaylistSong
                    
                    playlistSong.parseSong(song, playlist: playlist, order: order)
                    playlistSongs.add(playlistSong)
                    print("Created new playlist song with title: \(song.title)")
                    order += 1
                }
                
                let combinedSongs = NSMutableSet(set: playlist.playlistSongs)
                combinedSongs.addObjects(from: playlistSongs.allObjects)
                playlist.playlistSongs = combinedSongs
                playlist.modifiedDate = Date()
            }
            
            self.saveDatastoreWithCompletion { (error) -> () in
                if results?.count > 0 {
                    completion(results)
                } else {
                    completion(nil)
                }
            }
        } catch { completion(nil) }
    }
    
    func createPlaylistWithSongs(_ name: String, songs: [AnyObject]!, completion: @escaping (_ addedSongs: [AnyObject]?) -> ()) {
        let playlist = NSEntityDescription.insertNewObject(forEntityName: "Playlist",
            into: self.mainQueueContext) as! Playlist
        playlist.name = name
        playlist.playlistType = NSNumber(value: PlaylistType.none.rawValue as UInt)
        playlist.persistentID = ""
        
        let playlistSongs = NSMutableSet()
        var order = 0
        
        for song in songs as! [Song] {
            let playlistSong = NSEntityDescription.insertNewObject(forEntityName: "PlaylistSong",
                into: self.mainQueueContext) as! PlaylistSong
            
            playlistSong.parseSong(song, playlist: playlist, order: order)
            playlistSongs.add(playlistSong)
            print("Created new playlist song with title: \(song.title)")
            order += 1
        }
        
        playlist.playlistSongs = playlistSongs
        playlist.modifiedDate = Date()
        
        self.saveDatastoreWithCompletion { (error) -> () in
            completion(playlistSongs.allObjects as [AnyObject])
        }
    }
    
    func addSongsToPlaylist(_ songs: [AnyObject]!, playlist: Playlist, completion: @escaping (_ addedSongs: [AnyObject]?) -> ()) {
        let playlistSongs = NSMutableSet(set: playlist.playlistSongs)
        var order = playlistSongs.count
        
        for song in songs as! [Song] {
            let playlistSong = NSEntityDescription.insertNewObject(forEntityName: "PlaylistSong",
                into: self.mainQueueContext) as! PlaylistSong
            
            playlistSong.parseSong(song, playlist: playlist, order: order)
            playlistSongs.add(playlistSong)
            print("Created new playlist song with title: \(song.title)")
            order += 1
        }
        
        playlist.playlistSongs = playlistSongs
        playlist.modifiedDate = Date()
        
        self.saveDatastoreWithCompletion { (error) -> () in
            completion(playlistSongs.allObjects as [AnyObject])
        }
    }
    
    func createEmptyPlaylistWithName(_ name: String, playlistType: PlaylistType, completion: @escaping () -> ()) {
        let playlist = NSEntityDescription.insertNewObject(forEntityName: "Playlist",
            into: self.mainQueueContext) as! Playlist
        playlist.name = name
        playlist.playlistType = NSNumber(value: playlistType.rawValue as UInt)
        playlist.persistentID = ""
        playlist.modifiedDate = Date()
        
        self.saveDatastoreWithCompletion { (error) -> () in
            completion()
        } 
    }
    
    fileprivate func createPlaylistWithPlaylist(_ playlist: MPMediaPlaylist, context: NSManagedObjectContext) -> Playlist? {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Playlist")
        let predicate = NSPredicate(format: "persistentID = %@", String(playlist.persistentID))
        request.predicate = predicate
        let results: [AnyObject]?
        do {
            results = try context.fetch(request)
            if results?.count > 0 {
                // Update
                let existingPlaylist = results?[0] as! Playlist
                existingPlaylist.parsePlaylist(playlist)
                return existingPlaylist
            } else {
                let newPlaylist = NSEntityDescription.insertNewObject(forEntityName: "Playlist",
                    into: context) as! Playlist
                
                newPlaylist.parsePlaylist(playlist)
                
                for item in playlist.items {
                    if let title = item.title, let artist = item.artist {
                        DataManager.manager.datastore.songForSongName(title, artist: artist, completion: { (song) -> () in
                            if let playingSong = song {
                                self.addSongToPlaylist(newPlaylist, song: playingSong, originalPlaylist: nil, context: context)
                            }
                        })
                    }
                }
                
                print("Created playlist with name: \(newPlaylist.name) and type: \(newPlaylist.playlistType.intValue)")
                
                return newPlaylist
            }
        } catch { return nil }
    }
    
    fileprivate func addSongToPlaylist(_ playlist: Playlist, song: Song, originalPlaylist: MPMediaPlaylist?, context: NSManagedObjectContext) {
        let newPlaylistSong = NSEntityDescription.insertNewObject(forEntityName: "PlaylistSong",
            into: context) as! PlaylistSong
        newPlaylistSong.parsePlaylistSong(song, playlist: playlist, originalPlaylist: originalPlaylist)
    }
    
    func songForSongName(_ songName: String, artist: String, completion: (_ song: Song?) -> ()) {
        let request = NSFetchRequest<NSFetchRequestResult>()
        request.entity = NSEntityDescription.entity(forEntityName: "Song",
            in: self.mainQueueContext)
        
        request.fetchLimit = 1
        
        let predicate = NSPredicate(format: "title = %@ AND artist = %@", songName, artist)
        request.predicate = predicate
        
        let error: NSErrorPointer = nil
        let results: [AnyObject]?
        do {
            results = try self.mainQueueContext.fetch(request)
        } catch let error1 as NSError {
            error?.pointee = error1
            results = nil
        }
        
        if results?.count > 0 {
            if let song = results?[0] as? Song {
                completion(song)
            }
            
            completion(nil)
        }
        completion(nil)
    }
    
    // MARK: NSFetchedResultsControllers
    
    func artistsWithSortKey(_ sortKey: String, ascending: Bool, sectionNameKeyPath: String?) -> [AnyObject]? {
        let request = NSFetchRequest<NSFetchRequestResult>()
        request.entity = NSEntityDescription.entity(forEntityName: "Song",
            in: self.mainQueueContext)
        
        let predicate = NSPredicate(format: "(artist.length > 0)")
        request.predicate = predicate
        
        if let property: AnyObject = request.entity?.propertiesByName["artist"] {
            request.propertiesToFetch = [property]
            request.propertiesToGroupBy = [property]
        }
        
        request.resultType = NSFetchRequestResultType.dictionaryResultType
        request.returnsDistinctResults = true
        
        let sort = NSSortDescriptor(key: sortKey, ascending: ascending)
        request.sortDescriptors = [sort]
        
        do {
            return try self.mainQueueContext.fetch(request)
        } catch _ {
            return nil
        }
    }
    
    func artistsController(_ predicate: NSPredicate?, sortKey: String, ascending: Bool, sectionNameKeyPath: String?) -> NSFetchedResultsController<NSFetchRequestResult> {
        
        let request = NSFetchRequest<NSFetchRequestResult>()
        request.entity = NSEntityDescription.entity(forEntityName: "Artist",
            in: self.mainQueueContext)
        
        if let artistPredicate = predicate {
            request.predicate = artistPredicate
        }

        let sort = NSSortDescriptor(key: sortKey, ascending: ascending)
        request.sortDescriptors = [sort]
        
        return NSFetchedResultsController(fetchRequest: request,
        managedObjectContext: self.mainQueueContext,
        sectionNameKeyPath: sectionNameKeyPath,
        cacheName: nil)
    }
    
    func recommendationController(_ limit: Int) -> NSFetchedResultsController<NSFetchRequestResult> {
        
        let request = NSFetchRequest<NSFetchRequestResult>()
        request.entity = NSEntityDescription.entity(forEntityName: "Artist",
            in: self.mainQueueContext)
        
        request.fetchLimit = limit
        
        let sort = NSSortDescriptor(key: "lastPlayedDate", ascending: false)
        request.sortDescriptors = [sort]
        
        return NSFetchedResultsController(fetchRequest: request,
            managedObjectContext: self.mainQueueContext,
            sectionNameKeyPath: nil,
            cacheName: nil)
    }
    
    func plsylistSsongsControllerWithSortKey(_ sortKey: String, ascending: Bool, sectionNameKeyPath: String?) -> NSFetchedResultsController<NSFetchRequestResult> {
        
        let request = NSFetchRequest<NSFetchRequestResult>()
        request.entity = NSEntityDescription.entity(forEntityName: "PlaylistSong",
            in: self.mainQueueContext)
        
        let predicate = NSPredicate(format: "(artist.length > 0)")
        request.predicate = predicate
        
        let properties = NSMutableArray()
        
        if let artistProperty: AnyObject = request.entity?.propertiesByName["artist"] {
            properties.add(artistProperty)
        }
        
        request.propertiesToGroupBy = properties as [AnyObject]
        request.propertiesToFetch = properties as [AnyObject]
        request.returnsDistinctResults = true
        request.resultType = NSFetchRequestResultType.dictionaryResultType
        
        let sort = NSSortDescriptor(key: sortKey, ascending: ascending)
        request.sortDescriptors = [sort]
        
        return NSFetchedResultsController(fetchRequest: request,
            managedObjectContext: self.mainQueueContext,
            sectionNameKeyPath: sectionNameKeyPath,
            cacheName: ArtistsCacheName)
    }
    
    func artistsAlbumsControllerWithSortKey(_ artist: Artist,
        sortKey: String,
        ascending: Bool,
        sectionNameKeyPath: String?) -> NSFetchedResultsController<NSFetchRequestResult> {
        
        let request = NSFetchRequest<NSFetchRequestResult>()
        request.entity = NSEntityDescription.entity(forEntityName: "Album",
            in: self.mainQueueContext)
        
        let predicate = NSPredicate(format: "artist like %@", artist)
        request.predicate = predicate
        
        let groupBy = NSMutableArray()
        let fetch = NSMutableArray()
        
        if let albumProperty: AnyObject = request.entity?.propertiesByName["albumTitle"] {
            groupBy.add(albumProperty)
            fetch.add(albumProperty)
        }
        
        if let titleProperty: AnyObject = request.entity?.propertiesByName["title"] {
            groupBy.add(titleProperty)
            fetch.add(titleProperty)
        }
        
        if let artistProperty: AnyObject = request.entity?.propertiesByName["artist"] {
            groupBy.add(artistProperty)
            fetch.add(artistProperty)
        }
        
        if let albumTrackNumberProperty: AnyObject = request.entity?.propertiesByName["albumTrackNumber"] {
            groupBy.add(albumTrackNumberProperty)
            fetch.add(albumTrackNumberProperty)
        }
        
        if let artworkProperty: AnyObject = request.entity?.propertiesByName["artwork"] {
            groupBy.add(artworkProperty)
            fetch.add(artworkProperty)
        }
        
        if let albumTrackCountProperty: AnyObject = request.entity?.propertiesByName["albumTrackCount"] {
            groupBy.add(albumTrackCountProperty)
            fetch.add(albumTrackCountProperty)
        }
        
        if let playbackDurationProperty: AnyObject = request.entity?.propertiesByName["playbackDuration"] {
            groupBy.add(playbackDurationProperty)
            fetch.add(playbackDurationProperty)
        }
        
        request.propertiesToGroupBy = groupBy as [AnyObject]
        request.propertiesToFetch = fetch as [AnyObject]
        request.returnsDistinctResults = true
        request.resultType = NSFetchRequestResultType.dictionaryResultType
        
        let sort = NSSortDescriptor(key: sortKey, ascending: ascending)
        let sortTrackNumber = NSSortDescriptor(key: "albumTrackNumber", ascending: true)
        request.sortDescriptors = [sort, sortTrackNumber]
        
        return NSFetchedResultsController(fetchRequest: request,
            managedObjectContext: self.mainQueueContext,
            sectionNameKeyPath: sectionNameKeyPath,
            cacheName: ArtistsCacheName)
    }
    
    func albumsControllerWithSortKey(_ sortKey: String,
        ascending: Bool,
        sectionNameKeyPath: String?) -> NSFetchedResultsController<NSFetchRequestResult> {
        let request = NSFetchRequest<NSFetchRequestResult>()
            
        request.entity = NSEntityDescription.entity(forEntityName: "Album",
            in: self.mainQueueContext)
        
        let sort = NSSortDescriptor(key: sortKey, ascending: ascending)
        request.sortDescriptors = [sort]
        
        return NSFetchedResultsController(fetchRequest: request,
            managedObjectContext: self.mainQueueContext,
            sectionNameKeyPath: sectionNameKeyPath,
            cacheName: nil)
    }
    
    func songsControllerWithSortKey(_ sortKey: String,
        limit: NSInteger?,
        ascending: Bool,
        sectionNameKeyPath: String?) -> NSFetchedResultsController<NSFetchRequestResult> {
        
        let request = NSFetchRequest<NSFetchRequestResult>()
        
        if let fetchLimit = limit {
            request.fetchLimit = fetchLimit
        }
        
        request.entity = NSEntityDescription.entity(forEntityName: "Song",
            in: self.mainQueueContext)
        
        let sort = NSSortDescriptor(key: sortKey, ascending: ascending)
        request.sortDescriptors = [sort]
        
        return NSFetchedResultsController(fetchRequest: request,
            managedObjectContext: self.mainQueueContext,
            sectionNameKeyPath: sectionNameKeyPath,
            cacheName: nil)
    }
    
    func distinctArtistSongsWithSortKey(_ sortKey: String,
        limit: NSInteger?,
        ascending: Bool) -> NSArray?
    {
        
        let request = NSFetchRequest<NSFetchRequestResult>()
        request.entity = NSEntityDescription.entity(forEntityName: "Song",
            in: self.workerContext)
        
        request.fetchLimit = 100
        request.propertiesToFetch = ["persistentID", "lastPlayedDate", "artist"]
        request.returnsDistinctResults = true
        request.resultType = .dictionaryResultType
        
        let sort = NSSortDescriptor(key: sortKey, ascending: ascending)
        request.sortDescriptors = [sort]
        let results = try? self.workerContext.fetch(request)
        
        if let _ = limit {
            var recentArtists = Array<AnyObject>()
            
            if results?.count > 0 {
                for artistData in results as! [NSDictionary] {
                    
                    if recentArtists.count >= limit {
                        return recentArtists as NSArray
                    }
                    
                    var found = false
                    
                    for artist in recentArtists as! [NSDictionary] {
                        let artistName = artist.object(forKey: "artist") as! String
                        if artistName == artistData.object(forKey: "artist") as! String {
                            found = true
                        }
                    }
                    
                    if !found {
                        recentArtists.append(artistData)
                    }
                }
                
                return recentArtists as NSArray
            }
        }
        
        return nil
    }
    
    func recentlyPlayedSongs(
        limit: NSInteger?) -> NSArray?
    {
        let request = NSFetchRequest<NSFetchRequestResult>()
        request.entity = NSEntityDescription.entity(forEntityName: "Song",
            in: self.workerContext)
        
        if let fetchLimit = limit {
            request.fetchLimit = fetchLimit
        }
        
        request.propertiesToFetch = ["persistentID", "lastPlayedDate", "title", "artist"]
        request.resultType = .dictionaryResultType
        
        let sort = NSSortDescriptor(key: "lastPlayedDate", ascending: false)
        request.sortDescriptors = [sort]
        return try? self.workerContext.fetch(request) as NSArray
    }
    
    func lovedControllerWithSortKey(_ sortKey: String, ascending: Bool, sectionNameKeyPath: String?) -> NSFetchedResultsController<NSFetchRequestResult> {
        
        let request = NSFetchRequest<NSFetchRequestResult>()
        request.entity = NSEntityDescription.entity(forEntityName: "Song",
            in: self.mainQueueContext)
        
        let predicate = NSPredicate(format: "rating > 3")
        request.predicate = predicate
        
        request.returnsDistinctResults = true
        
        let sort = NSSortDescriptor(key: sortKey, ascending: ascending)
        request.sortDescriptors = [sort]
        
        return NSFetchedResultsController(fetchRequest: request,
            managedObjectContext: self.mainQueueContext,
            sectionNameKeyPath: sectionNameKeyPath,
            cacheName: ArtistsCacheName)
    }
    
    func playlistsControllerWithSortKey(sortKey: String!,
        ascending: Bool,
        limit: NSInteger,
        sectionNameKeyPath: String?) -> NSFetchedResultsController<NSFetchRequestResult> {
        let request = NSFetchRequest<NSFetchRequestResult>()
        request.entity = NSEntityDescription.entity(forEntityName: "Playlist",
            in: self.mainQueueContext)
        request.fetchLimit = limit
        
        let sort = NSSortDescriptor(key: sortKey, ascending: ascending)
        request.sortDescriptors = [sort]
        
        return NSFetchedResultsController(fetchRequest: request,
            managedObjectContext: self.mainQueueContext,
            sectionNameKeyPath: sectionNameKeyPath,
            cacheName: nil)
    }
    
    func playlistsControllerWithSectionName(_ sectionNameKeyPath: String?,
        predicate: NSPredicate?) -> NSFetchedResultsController<NSFetchRequestResult> {
        let request = NSFetchRequest<NSFetchRequestResult>()
        request.entity = NSEntityDescription.entity(forEntityName: "Playlist",
            in: self.mainQueueContext)
        
        if let playlistPredicate = predicate {
            request.predicate = playlistPredicate
        }
        
        let sort = NSSortDescriptor(key: "name", ascending: true)
        let sortType = NSSortDescriptor(key: "playlistType", ascending: false)
        request.sortDescriptors = [sortType, sort]
        
        return NSFetchedResultsController(fetchRequest: request,
            managedObjectContext: self.mainQueueContext,
            sectionNameKeyPath: sectionNameKeyPath,
            cacheName: nil)
    }
    
    func playlistSongsControllerWithPlaylist(_ playlist: Playlist,
        sectionNameKeyPath: String?) -> NSFetchedResultsController<NSFetchRequestResult> {
        let request = NSFetchRequest<NSFetchRequestResult>()
        request.entity = NSEntityDescription.entity(forEntityName: "PlaylistSong",
            in: self.mainQueueContext)
        
        let sort = NSSortDescriptor(key: "persistentID", ascending: true)
        request.sortDescriptors = [sort]
        
        return NSFetchedResultsController(fetchRequest: request,
            managedObjectContext: self.mainQueueContext,
            sectionNameKeyPath: sectionNameKeyPath,
            cacheName: nil)
    }
    
    func updatePlaylistSongOrder(_ playlistsongSource: Playlist,
        sectionNameKeyPath: String?) -> NSFetchedResultsController<NSFetchRequestResult> {
        let request = NSFetchRequest<NSFetchRequestResult>()
        request.entity = NSEntityDescription.entity(forEntityName: "PlaylistSong",
            in: self.mainQueueContext)
        
        let sort = NSSortDescriptor(key: "persistentID", ascending: true)
        request.sortDescriptors = [sort]
            
        return NSFetchedResultsController(fetchRequest: request,
            managedObjectContext: self.mainQueueContext,
            sectionNameKeyPath: sectionNameKeyPath,
            cacheName: nil)
    }
    
    func deletePlaylistWithPlaylist(_ playlist: Playlist, completion: @escaping (_ error: NSErrorPointer?) -> ()) {
        
        self.mainQueueContext.perform { () -> Void in
            var error: NSError?
            let object: NSManagedObject?
            do {
                object = try self.mainQueueContext.existingObject(with: playlist.objectID)
            } catch let error1 as NSError {
                error = error1
                object = nil
            } catch {
                fatalError()
            }
            
            if error == nil {
                self.mainQueueContext.delete(object!)
            }
                        
            self.saveDatastoreWithCompletion { (error) -> () in
                if error != nil {
                    completion(error)
                } else {
                    completion(nil)
                }
            }
        }
    }
    
    // MARK: Fetching
    
    // MARK: Saving
    
    func saveDatastoreWithCompletion(_ completion: @escaping (_ error: NSErrorPointer) -> ()) {
        let totalStartTime = Date()
        self.workerContext.perform { () -> Void in
            let error: NSErrorPointer = nil
            var startTime = Date()
            do {
                try self.workerContext.save()
            } catch let error1 as NSError {
                error?.pointee = error1
            } catch {
                fatalError()
            }
            
            var endTime: Date!
            var executionTime: TimeInterval!
            
            if error == nil {
                endTime = Date()
                executionTime = endTime.timeIntervalSince(startTime)
                NSLog("workerContext saveStore executionTime = %f", (executionTime * 1000));
                
                startTime = Date()
                self.mainQueueContext.performAndWait({ () -> Void in
                    do {
                        try self.mainQueueContext.save()
                    } catch let error1 as NSError {
                        error?.pointee = error1
                    } catch {
                        fatalError()
                    }
                })
                
                if error == nil {
                    endTime = Date()
                    executionTime = endTime.timeIntervalSince(startTime)
                    
                    NSLog("mainQueueContext saveStore executionTime = %f",
                    (executionTime * 1000));
                    
                    startTime = Date()
                    self.saveContext.performAndWait({ () -> Void in
                        do {
                            try self.saveContext.save()
                        } catch { }
                    })
                }
            }
            
            endTime = Date()
            executionTime = endTime.timeIntervalSince(startTime)
            NSLog("workerContext saveStore executionTime = %f", (executionTime * 1000));
            
            let totalEndTime = Date()
            executionTime = totalEndTime.timeIntervalSince(totalStartTime)
            NSLog("Total Time saveStore executionTime = %f", (executionTime * 1000));

            completion(error)
        }
    }
    
    fileprivate func clearCache() {
        NSFetchedResultsController<NSFetchRequestResult>.deleteCache(withName: nil)
    }
    
    fileprivate func deleteAllObjectsInStoreWithCompletion(_ completion: (_ error: NSError?) -> ()) {
        clearCache()
        
        self.mainQueueContext.lock()
        self.workerContext.lock()
        
        self.mainQueueContext.reset()
        self.workerContext.reset()
        
        
        if let storeCoordinator = self.mainQueueContext.persistentStoreCoordinator {
            if let store = storeCoordinator.persistentStores.first {
                let storeURL = storeCoordinator.url(for: store)
                
                do {
                    try storeCoordinator.remove(store)
                    do {
                        try FileManager.default.removeItem(at: storeURL)
                    } catch { }
                } catch { }
                
                do {
                    try persistentStoreCoordinator.addPersistentStore(ofType: NSSQLiteStoreType,
                        configurationName: nil,
                        at: storeURL,
                        options: nil)
                    self.workerContext.unlock()
                    self.mainQueueContext.unlock()
                    completion(nil)
                } catch {}
            }
        }
    }
}
