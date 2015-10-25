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
    
    private func configure() {
        let modelURL = NSBundle.mainBundle().URLForResource("Muz", withExtension: "momd")
        self.managedObjectModel = NSManagedObjectModel(contentsOfURL: modelURL!)!
        
        let storeUrlString = String(format: "%@.sqlite", self.storeName)
        let paths = NSFileManager.defaultManager().URLsForDirectory(NSSearchPathDirectory.DocumentDirectory, inDomains: NSSearchPathDomainMask.UserDomainMask)
        if let documentsURL = paths.last {
            let storeURL = documentsURL.URLByAppendingPathComponent(storeUrlString)
            self.persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
            
            do {
                try self.persistentStoreCoordinator.addPersistentStoreWithType(NSSQLiteStoreType,
                    configuration: nil,
                    URL: storeURL,
                    options: nil)
            } catch {}
            
            self.saveContext = NSManagedObjectContext(concurrencyType: NSManagedObjectContextConcurrencyType.PrivateQueueConcurrencyType)
            self.saveContext.persistentStoreCoordinator = self.persistentStoreCoordinator
            self.saveContext.undoManager = nil
            
            self.mainQueueContext = NSManagedObjectContext(concurrencyType: NSManagedObjectContextConcurrencyType.MainQueueConcurrencyType)
            self.mainQueueContext.undoManager = nil
            self.mainQueueContext.parentContext = self.saveContext
            
            self.workerContext = NSManagedObjectContext(concurrencyType: NSManagedObjectContextConcurrencyType.PrivateQueueConcurrencyType)
            self.workerContext.undoManager = nil
            self.workerContext.parentContext = self.mainQueueContext
            
        }
    }
    
    // MARK: Add songs
    
    func addSongs(songs: NSArray?, completion: (addedItems: [AnyObject], error: NSErrorPointer) -> ()) {
        let context = self.mainQueueContext
        context.performBlock { () -> Void in
            let startTime = NSDate()
            
            let request = NSFetchRequest(entityName: "Song")
            
            let addedSongs = NSMutableArray(capacity: songs?.count ?? 0)
            let existedSongs = NSMutableArray(capacity: songs?.count ?? 0)
            
            var count = 0
            
            for song in (songs as? [MPMediaItem])! {
                count++
                if let artist = song.artist, let title = song.title {
                    
                    let predicate = NSPredicate(format: "title = %@ AND artist = %@", title, artist)
                    request.fetchLimit = 1
                    request.predicate = predicate
                    let results: [AnyObject]?
                    do {
                        results = try context.executeFetchRequest(request)
                    } catch {
                        fatalError()
                    }
                    
                    var managedSong: Song!
                    if results?.count > 0 {
                        managedSong = results?[0] as! Song
                    } else {
                        managedSong = NSEntityDescription.insertNewObjectForEntityForName("Song",
                            inManagedObjectContext: context) as! Song
                        managedSong.parseItem(song)
                    }
                    
                    addedSongs.addObject(managedSong)
                }
            }
            
            self.saveDatastoreWithCompletion({ (error) -> () in
                let endTime = NSDate()
                let executionTime = endTime.timeIntervalSinceDate(startTime)
                NSLog("addSongs() - executionTime = %f\n addedSongs count: %d\n existedSongs count: %d", (executionTime * 1000), addedSongs.count, existedSongs.count);
                
                completion(addedItems: addedSongs as [AnyObject], error: error)
            })
        }
    }
    
    private func dispatchAddBlock(dispatchBlock: () -> ()) -> () {
        dispatch_async(dispatch_get_main_queue(), dispatchBlock)
    }
    
    
    func resetLibrary(completion: (error: NSErrorPointer) -> ()) {
        self.workerContext.performBlock { () -> Void in
            var error: NSError?
            let request = NSFetchRequest(entityName: "Artist")
            let results: [AnyObject]?
            do {
                results = try self.workerContext.executeFetchRequest(request)
            } catch let error1 as NSError {
                error = error1
                results = nil
            } catch {
                fatalError()
            }
            
            for artist in results as! [Artist] {
                
                for album in artist.albums.allObjects as! [Album] {
                    for song in album.songs.allObjects as! [Song] {
                        self.workerContext.deleteObject(song)
                    }
                    
                    self.workerContext.deleteObject(album)
                }
                
                self.workerContext.deleteObject(artist)
            }
            
            completion(error: &error)
        }
    }
    
    /**
    Adds artists to the datastore.
    
    - parameter artists:    The artists you want to add.
    - parameter completion: The completion block called at the end of the execution.
    */
    func addArtists(artists: NSArray?, completion: (addedItems: [AnyObject], error: NSErrorPointer) -> (),
        progress: (addedItems: [AnyObject], total: Int) -> ())
    {
        let context = self.workerContext
        context.performBlock { () -> Void in
           
            let startTime = NSDate()
            let request = NSFetchRequest(entityName: "Artist")
            let addedArtists = NSMutableArray(capacity: artists?.count ?? 0)
            
            artists?.enumerateObjectsUsingBlock({ (artist, idx, stop) -> Void in
                if let item = artist as? MPMediaItem {
                    
                    if let artistName = item.artist {
                        
                        let predicate = NSPredicate(format: "name = %@", artistName)
                        request.fetchLimit = 1
                        request.predicate = predicate
                        let results: [AnyObject]?
                        do {
                            results = try context.executeFetchRequest(request)
                        } catch {
                            fatalError()
                        }
                        
                        var managedArtist: Artist!
                        if results?.count > 0 {
                            managedArtist = results?[0] as! Artist
                        } else {
                            managedArtist = NSEntityDescription.insertNewObjectForEntityForName("Artist",
                                inManagedObjectContext: context) as! Artist
                        }
                        
                        managedArtist.parseItem(item)
                        
                        // Add albums
                        self.addAlbumForItem(item: item, artist: managedArtist, context: context)
                        
                        addedArtists.addObject(managedArtist)
                        
                        progress(addedItems: addedArtists as [AnyObject], total: artists?.count ?? 0)
                    }
                }
            })

            self.saveDatastoreWithCompletion({ (error) -> () in
                let endTime = NSDate()
                let executionTime = endTime.timeIntervalSinceDate(startTime)
                NSLog("addArtists() - executionTime = %f\n addedSongs count: %d\n existedSongs count: %d", (executionTime * 1000), addedArtists.count);

                completion(addedItems: addedArtists as [AnyObject], error: error)
            })
        }
    }
    
    func addAlbumsForArtist(artist artist: Artist, albums: NSArray?, completion: (addedItems: [AnyObject], error: NSErrorPointer) -> ()) {
        self.workerContext.performBlock { () -> Void in
            
            let startTime = NSDate()
            let request = NSFetchRequest(entityName: "Album")
            let addedAlbums = NSMutableArray(capacity: albums?.count ?? 0)
            
            albums?.enumerateObjectsUsingBlock({ (album, idx, stop) -> Void in
                if let item = album as? MPMediaItem {
                    
                    if let title = item.albumTitle {
                        
                        let predicate = NSPredicate(format: "title = %@", title)
                        request.fetchLimit = 1
                        request.predicate = predicate
                        let results: [AnyObject]?
                        do {
                            results = try self.workerContext.executeFetchRequest(request)
                        } catch {
                            fatalError()
                        }
                        
                        var managedAlbum: Album!
                        if results?.count > 0 {
                            managedAlbum = results?[0] as! Album
                        } else {
                            managedAlbum = NSEntityDescription.insertNewObjectForEntityForName("Album",
                                inManagedObjectContext: self.workerContext) as! Album
                            addedAlbums.addObject(managedAlbum)
                        }
                        
                        managedAlbum.parseItem(item)
                        self.addSongForItem(item: item, album: managedAlbum, context: self.workerContext)
                        
                        artist.addAlbum(managedAlbum)
                    }
                }

            })
            
            artist.modifiedDate = NSDate()
            
            self.saveDatastoreWithCompletion({ (error) -> () in
                let endTime = NSDate()
                let executionTime = endTime.timeIntervalSinceDate(startTime)
                NSLog("addAlbums() - executionTime = %f\n addAlbums count: %d", (executionTime * 1000), addedAlbums.count);
                
                completion(addedItems: addedAlbums as [AnyObject], error: error)
            })
        }

    }
    
    /**
    Add album for item.
    
    - parameter item: The item you want to use to add a new album from.
    
    - returns: The created/existing album or nil.
    */
    func addAlbumForItem(item item: MPMediaItem, artist: Artist, context: NSManagedObjectContext) {
        let request = NSFetchRequest(entityName: "Album")
        
        let predicate = NSPredicate(format: "title = %@", item.albumTitle ?? "")
        request.fetchLimit = 1
        request.predicate = predicate
        let results: [AnyObject]?
        do {
            results = try context.executeFetchRequest(request)
            var managedAlbum: Album!
            if results?.count > 0 {
                managedAlbum = results?[0] as! Album
            } else {
                managedAlbum = NSEntityDescription.insertNewObjectForEntityForName("Album",
                    inManagedObjectContext: context) as! Album
            }
            
            managedAlbum.parseItem(item)
            managedAlbum.artist = artist
            
            self.addSongForItem(item: item, album: managedAlbum, context: context)
        } catch { }
    }
    
    func artistForSong(song song: Song) -> Artist? {
        let request = NSFetchRequest(entityName: "Artist")
        let predicate = NSPredicate(format: "name = %@", song.artist)
        request.fetchLimit = 1
        request.predicate = predicate
        let results: [AnyObject]?
        do {
            results = try self.workerContext.executeFetchRequest(request)
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
    
    func artistForSongData(song song: NSDictionary) -> Artist? {
        let request = NSFetchRequest(entityName: "Artist")
        let predicate = NSPredicate(format: "name = %@", song.objectForKey("artist") as! String)
        request.fetchLimit = 1
        request.predicate = predicate
        let results: [AnyObject]?
        do {
            results = try self.workerContext.executeFetchRequest(request)
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
    func addSongForItem(item item: MPMediaItem, album: Album, context: NSManagedObjectContext) {
        
        let managedSong = NSEntityDescription.insertNewObjectForEntityForName("Song",
            inManagedObjectContext: context) as! Song
        
        managedSong.parseItem(item)
        managedSong.album = album
    }
    
    func updateSong(song song: Song, completion: () -> ()) {
        song.lastPlayedDate = NSDate()
        
        self.saveDatastoreWithCompletion({ (error) -> () in
            completion()
        })
    }
    
    func updatePlaylist(playlist playlist: Playlist, completion: () -> ()) {
        playlist.modifiedDate = NSDate()
        
        self.saveDatastoreWithCompletion({ (error) -> () in
            print("Updated playlist with new modified date: \(playlist.modifiedDate)")
            completion()
        })
    }
    
    func addPlaylists(playlists: [AnyObject]?, completion: (addedPlaylists: [AnyObject]?) -> ()) {
        
        self.mainQueueContext.performBlock { () -> Void in
            
            let request = NSFetchRequest()
            request.entity = NSEntityDescription.entityForName("Playlist",
                inManagedObjectContext: self.mainQueueContext)
            
            let results = try? self.mainQueueContext.executeFetchRequest(request)
            
            if results?.count > 0 {
                for existingPlaylist in results as! [Playlist] {
                    if existingPlaylist.persistentID != "" {
                        self.mainQueueContext.deleteObject(existingPlaylist)
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

    func createPlaylistWithSimiliarArtists(artist: String!, artists: [AnyObject]!,
        fetchLimit: NSInteger,
        name: String!,
        playlistType: PlaylistType,
        completion: (addedSongs: [AnyObject]?) -> ()) {
        
        clearCache()
        
        let request = NSFetchRequest(entityName: "Song")
    
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
            results = try self.workerContext.executeFetchRequest(request)
            
            if results?.count > 0 {
                
                // Create smart playlist based on artists.
                let playlist = NSEntityDescription.insertNewObjectForEntityForName("Playlist",
                    inManagedObjectContext: self.workerContext) as! Playlist
                playlist.name = name
                playlist.playlistType = NSNumber(unsignedLong: playlistType.rawValue)
                playlist.persistentID = ""
                playlist.modifiedDate = NSDate()
                
                // Create PlaySongs
                let playlistSongs = NSMutableSet()
                var order = 0
                
                for song in results as! [Song] {
                    let playlistSong = NSEntityDescription.insertNewObjectForEntityForName("PlaylistSong",
                        inManagedObjectContext: self.workerContext) as! PlaylistSong
                    
                    playlistSong.parseSong(song, playlist: playlist, order: order)
                    playlistSongs.addObject(playlistSong)
                    print("Created new playlist song with title: \(song.title)")
                    order++
                }
                
                playlist.playlistSongs = playlistSongs
            }
            
            self.saveDatastoreWithCompletion { (error) -> () in
                if results?.count > 0 {
                    completion(addedSongs: results)
                } else {
                    completion(addedSongs: nil)
                }
            }
        } catch { }
    }
    
    func createPlaylistWithArtist(artist: String!,
        name: String!,
        playlistType: PlaylistType,
        completion: (addedSongs: [AnyObject]?) -> ()) {
            
        clearCache()
        
        let request = NSFetchRequest(entityName: "Song")
        
        let predicate = NSPredicate(format: "(artist contains[cd] %@)", artist)
        request.predicate = predicate
        
        let results: [AnyObject]?
        do {
            results = try self.mainQueueContext.executeFetchRequest(request)
            if results?.count > 0 {
                
                // Create smart playlist based on artists.
                let playlist = NSEntityDescription.insertNewObjectForEntityForName("Playlist",
                    inManagedObjectContext: self.mainQueueContext) as! Playlist
                playlist.name = name
                playlist.playlistType = NSNumber(unsignedLong: playlistType.rawValue)
                playlist.persistentID = ""
                playlist.modifiedDate = NSDate()
                
                // Create PlaySongs
                let playlistSongs = NSMutableSet()
                var order = 0
                
                for song in results as! [Song] {
                    let playlistSong = NSEntityDescription.insertNewObjectForEntityForName("PlaylistSong",
                        inManagedObjectContext: self.mainQueueContext) as! PlaylistSong
                    
                    playlistSong.parseSong(song, playlist: playlist, order: order)
                    playlistSongs.addObject(playlistSong)
                    print("Created new playlist song with title: \(song.title)")
                    order++
                }
                
                playlist.playlistSongs = playlistSongs
            }
            
            self.saveDatastoreWithCompletion { (error) -> () in
                if results?.count > 0 {
                    completion(addedSongs: results)
                } else {
                    completion(addedSongs: nil)
                }
            }
        } catch { completion(addedSongs: nil) }
    }
    
    // TODO: Change this to use worker context.
    func addArtistSongsToPlaylist(playlist: Playlist, artist: String!,
        completion: (addedSongs: [AnyObject]?) -> ()) {
            
        clearCache()
        
        let request = NSFetchRequest(entityName: "Song")
        
        let predicate = NSPredicate(format: "(artist contains[cd] %@)", artist)
        request.predicate = predicate
        
        let results: [AnyObject]?
        do {
            results = try self.mainQueueContext.executeFetchRequest(request)
            if results?.count > 0 {
                // Create PlaySongs
                let playlistSongs = NSMutableSet()
                var order = playlist.playlistSongs.count
                
                for song in results as! [Song] {
                    let playlistSong = NSEntityDescription.insertNewObjectForEntityForName("PlaylistSong",
                        inManagedObjectContext: self.mainQueueContext) as! PlaylistSong
                    
                    playlistSong.parseSong(song, playlist: playlist, order: order)
                    playlistSongs.addObject(playlistSong)
                    print("Created new playlist song with title: \(song.title)")
                    order++
                }
                
                let combinedSongs = NSMutableSet(set: playlist.playlistSongs)
                combinedSongs.addObjectsFromArray(playlistSongs.allObjects)
                playlist.playlistSongs = combinedSongs
                playlist.modifiedDate = NSDate()
            }
            
            self.saveDatastoreWithCompletion { (error) -> () in
                if results?.count > 0 {
                    completion(addedSongs: results)
                } else {
                    completion(addedSongs: nil)
                }
            }
        } catch { completion(addedSongs: nil) }
    }
    
    func createPlaylistWithSongs(name: String, songs: [AnyObject]!, completion: (addedSongs: [AnyObject]?) -> ()) {
        let playlist = NSEntityDescription.insertNewObjectForEntityForName("Playlist",
            inManagedObjectContext: self.mainQueueContext) as! Playlist
        playlist.name = name
        playlist.playlistType = NSNumber(unsignedLong: PlaylistType.None.rawValue)
        playlist.persistentID = ""
        
        let playlistSongs = NSMutableSet()
        var order = 0
        
        for song in songs as! [Song] {
            let playlistSong = NSEntityDescription.insertNewObjectForEntityForName("PlaylistSong",
                inManagedObjectContext: self.mainQueueContext) as! PlaylistSong
            
            playlistSong.parseSong(song, playlist: playlist, order: order)
            playlistSongs.addObject(playlistSong)
            print("Created new playlist song with title: \(song.title)")
            order++
        }
        
        playlist.playlistSongs = playlistSongs
        playlist.modifiedDate = NSDate()
        
        self.saveDatastoreWithCompletion { (error) -> () in
            completion(addedSongs: playlistSongs.allObjects)
        }
    }
    
    func addSongsToPlaylist(songs: [AnyObject]!, playlist: Playlist, completion: (addedSongs: [AnyObject]?) -> ()) {
        let playlistSongs = NSMutableSet(set: playlist.playlistSongs)
        var order = playlistSongs.count
        
        for song in songs as! [Song] {
            let playlistSong = NSEntityDescription.insertNewObjectForEntityForName("PlaylistSong",
                inManagedObjectContext: self.mainQueueContext) as! PlaylistSong
            
            playlistSong.parseSong(song, playlist: playlist, order: order)
            playlistSongs.addObject(playlistSong)
            print("Created new playlist song with title: \(song.title)")
            order++
        }
        
        playlist.playlistSongs = playlistSongs
        playlist.modifiedDate = NSDate()
        
        self.saveDatastoreWithCompletion { (error) -> () in
            completion(addedSongs: playlistSongs.allObjects)
        }
    }
    
    func createEmptyPlaylistWithName(name: String, playlistType: PlaylistType, completion: () -> ()) {
        let playlist = NSEntityDescription.insertNewObjectForEntityForName("Playlist",
            inManagedObjectContext: self.mainQueueContext) as! Playlist
        playlist.name = name
        playlist.playlistType = NSNumber(unsignedLong: playlistType.rawValue)
        playlist.persistentID = ""
        playlist.modifiedDate = NSDate()
        
        self.saveDatastoreWithCompletion { (error) -> () in
            completion()
        } 
    }
    
    private func createPlaylistWithPlaylist(playlist: MPMediaPlaylist, context: NSManagedObjectContext) -> Playlist? {
        let request = NSFetchRequest(entityName: "Playlist")
        let predicate = NSPredicate(format: "persistentID = %@", String(playlist.persistentID))
        request.predicate = predicate
        let results: [AnyObject]?
        do {
            results = try context.executeFetchRequest(request)
            if results?.count > 0 {
                // Update
                let existingPlaylist = results?[0] as! Playlist
                existingPlaylist.parsePlaylist(playlist)
                return existingPlaylist
            } else {
                let newPlaylist = NSEntityDescription.insertNewObjectForEntityForName("Playlist",
                    inManagedObjectContext: context) as! Playlist
                
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
                
                print("Created playlist with name: \(newPlaylist.name) and type: \(newPlaylist.playlistType.integerValue)")
                
                return newPlaylist
            }
        } catch { return nil }
    }
    
    private func addSongToPlaylist(playlist: Playlist, song: Song, originalPlaylist: MPMediaPlaylist?, context: NSManagedObjectContext) {
        let newPlaylistSong = NSEntityDescription.insertNewObjectForEntityForName("PlaylistSong",
            inManagedObjectContext: context) as! PlaylistSong
        newPlaylistSong.parsePlaylistSong(song, playlist: playlist, originalPlaylist: originalPlaylist)
    }
    
    func songForSongName(songName: String, artist: String, completion: (song: Song?) -> ()) {
        let request = NSFetchRequest()
        request.entity = NSEntityDescription.entityForName("Song",
            inManagedObjectContext: self.mainQueueContext)
        
        request.fetchLimit = 1
        
        let predicate = NSPredicate(format: "title = %@ AND artist = %@", songName, artist)
        request.predicate = predicate
        
        let error = NSErrorPointer()
        let results: [AnyObject]?
        do {
            results = try self.mainQueueContext.executeFetchRequest(request)
        } catch let error1 as NSError {
            error.memory = error1
            results = nil
        }
        
        if results?.count > 0 {
            if let song = results?[0] as? Song {
                completion(song: song)
            }
            
            completion(song: nil)
        }
        completion(song: nil)
    }
    
    // MARK: NSFetchedResultsControllers
    
    func artistsWithSortKey(sortKey: String, ascending: Bool, sectionNameKeyPath: String?) -> [AnyObject]? {
        let request = NSFetchRequest()
        request.entity = NSEntityDescription.entityForName("Song",
            inManagedObjectContext: self.mainQueueContext)
        
        let predicate = NSPredicate(format: "(artist.length > 0)")
        request.predicate = predicate
        
        if let property: AnyObject = request.entity?.propertiesByName["artist"] {
            request.propertiesToFetch = [property]
            request.propertiesToGroupBy = [property]
        }
        
        request.resultType = NSFetchRequestResultType.DictionaryResultType
        request.returnsDistinctResults = true
        
        let sort = NSSortDescriptor(key: sortKey, ascending: ascending)
        request.sortDescriptors = [sort]
        
        do {
            return try self.mainQueueContext.executeFetchRequest(request)
        } catch _ {
            return nil
        }
    }
    
    func artistsController(predicate: NSPredicate?, sortKey: String, ascending: Bool, sectionNameKeyPath: String?) -> NSFetchedResultsController {
        
        let request = NSFetchRequest()
        request.entity = NSEntityDescription.entityForName("Artist",
            inManagedObjectContext: self.mainQueueContext)
        
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
    
    func recommendationController(limit: Int) -> NSFetchedResultsController {
        
        let request = NSFetchRequest()
        request.entity = NSEntityDescription.entityForName("Artist",
            inManagedObjectContext: self.mainQueueContext)
        
        request.fetchLimit = limit
        
        let sort = NSSortDescriptor(key: "lastPlayedDate", ascending: false)
        request.sortDescriptors = [sort]
        
        return NSFetchedResultsController(fetchRequest: request,
            managedObjectContext: self.mainQueueContext,
            sectionNameKeyPath: nil,
            cacheName: nil)
    }
    
    func plsylistSsongsControllerWithSortKey(sortKey: String, ascending: Bool, sectionNameKeyPath: String?) -> NSFetchedResultsController {
        
        let request = NSFetchRequest()
        request.entity = NSEntityDescription.entityForName("PlaylistSong",
            inManagedObjectContext: self.mainQueueContext)
        
        let predicate = NSPredicate(format: "(artist.length > 0)")
        request.predicate = predicate
        
        let properties = NSMutableArray()
        
        if let artistProperty: AnyObject = request.entity?.propertiesByName["artist"] {
            properties.addObject(artistProperty)
        }
        
        request.propertiesToGroupBy = properties as [AnyObject]
        request.propertiesToFetch = properties as [AnyObject]
        request.returnsDistinctResults = true
        request.resultType = NSFetchRequestResultType.DictionaryResultType
        
        let sort = NSSortDescriptor(key: sortKey, ascending: ascending)
        request.sortDescriptors = [sort]
        
        return NSFetchedResultsController(fetchRequest: request,
            managedObjectContext: self.mainQueueContext,
            sectionNameKeyPath: sectionNameKeyPath,
            cacheName: ArtistsCacheName)
    }
    
    func artistsAlbumsControllerWithSortKey(artist: Artist,
        sortKey: String,
        ascending: Bool,
        sectionNameKeyPath: String?) -> NSFetchedResultsController {
        
        let request = NSFetchRequest()
        request.entity = NSEntityDescription.entityForName("Album",
            inManagedObjectContext: self.mainQueueContext)
        
        let predicate = NSPredicate(format: "artist like %@", artist)
        request.predicate = predicate
        
        let groupBy = NSMutableArray()
        let fetch = NSMutableArray()
        
        if let albumProperty: AnyObject = request.entity?.propertiesByName["albumTitle"] {
            groupBy.addObject(albumProperty)
            fetch.addObject(albumProperty)
        }
        
        if let titleProperty: AnyObject = request.entity?.propertiesByName["title"] {
            groupBy.addObject(titleProperty)
            fetch.addObject(titleProperty)
        }
        
        if let artistProperty: AnyObject = request.entity?.propertiesByName["artist"] {
            groupBy.addObject(artistProperty)
            fetch.addObject(artistProperty)
        }
        
        if let albumTrackNumberProperty: AnyObject = request.entity?.propertiesByName["albumTrackNumber"] {
            groupBy.addObject(albumTrackNumberProperty)
            fetch.addObject(albumTrackNumberProperty)
        }
        
        if let artworkProperty: AnyObject = request.entity?.propertiesByName["artwork"] {
            groupBy.addObject(artworkProperty)
            fetch.addObject(artworkProperty)
        }
        
        if let albumTrackCountProperty: AnyObject = request.entity?.propertiesByName["albumTrackCount"] {
            groupBy.addObject(albumTrackCountProperty)
            fetch.addObject(albumTrackCountProperty)
        }
        
        if let playbackDurationProperty: AnyObject = request.entity?.propertiesByName["playbackDuration"] {
            groupBy.addObject(playbackDurationProperty)
            fetch.addObject(playbackDurationProperty)
        }
        
        request.propertiesToGroupBy = groupBy as [AnyObject]
        request.propertiesToFetch = fetch as [AnyObject]
        request.returnsDistinctResults = true
        request.resultType = NSFetchRequestResultType.DictionaryResultType
        
        let sort = NSSortDescriptor(key: sortKey, ascending: ascending)
        let sortTrackNumber = NSSortDescriptor(key: "albumTrackNumber", ascending: true)
        request.sortDescriptors = [sort, sortTrackNumber]
        
        return NSFetchedResultsController(fetchRequest: request,
            managedObjectContext: self.mainQueueContext,
            sectionNameKeyPath: sectionNameKeyPath,
            cacheName: ArtistsCacheName)
    }
    
    func albumsControllerWithSortKey(sortKey: String,
        ascending: Bool,
        sectionNameKeyPath: String?) -> NSFetchedResultsController {
        let request = NSFetchRequest()
            
        request.entity = NSEntityDescription.entityForName("Album",
            inManagedObjectContext: self.mainQueueContext)
        
        let sort = NSSortDescriptor(key: sortKey, ascending: ascending)
        request.sortDescriptors = [sort]
        
        return NSFetchedResultsController(fetchRequest: request,
            managedObjectContext: self.mainQueueContext,
            sectionNameKeyPath: sectionNameKeyPath,
            cacheName: nil)
    }
    
    func songsControllerWithSortKey(sortKey: String,
        limit: NSInteger?,
        ascending: Bool,
        sectionNameKeyPath: String?) -> NSFetchedResultsController {
        
        let request = NSFetchRequest()
        
        if let fetchLimit = limit {
            request.fetchLimit = fetchLimit
        }
        
        request.entity = NSEntityDescription.entityForName("Song",
            inManagedObjectContext: self.mainQueueContext)
        
        let sort = NSSortDescriptor(key: sortKey, ascending: ascending)
        request.sortDescriptors = [sort]
        
        return NSFetchedResultsController(fetchRequest: request,
            managedObjectContext: self.mainQueueContext,
            sectionNameKeyPath: sectionNameKeyPath,
            cacheName: nil)
    }
    
    func distinctArtistSongsWithSortKey(sortKey: String,
        limit: NSInteger?,
        ascending: Bool) -> NSArray?
    {
        
        let request = NSFetchRequest()
        request.entity = NSEntityDescription.entityForName("Song",
            inManagedObjectContext: self.workerContext)
        
        request.fetchLimit = 100
        request.propertiesToFetch = ["persistentID", "lastPlayedDate", "artist"]
        request.returnsDistinctResults = true
        request.resultType = .DictionaryResultType
        
        let sort = NSSortDescriptor(key: sortKey, ascending: ascending)
        request.sortDescriptors = [sort]
        let results = try? self.workerContext.executeFetchRequest(request)
        
        if let _ = limit {
            var recentArtists = Array<AnyObject>()
            
            if results?.count > 0 {
                for artistData in results as! [NSDictionary] {
                    
                    if recentArtists.count >= limit {
                        return recentArtists
                    }
                    
                    var found = false
                    
                    for artist in recentArtists as! [NSDictionary] {
                        let artistName = artist.objectForKey("artist") as! String
                        if artistName == artistData.objectForKey("artist") as! String {
                            found = true
                        }
                    }
                    
                    if !found {
                        recentArtists.append(artistData)
                    }
                }
                
                return recentArtists
            }
        }
        
        return nil
    }
    
    func recentlyPlayedSongs(
        limit limit: NSInteger?) -> NSArray?
    {
        let request = NSFetchRequest()
        request.entity = NSEntityDescription.entityForName("Song",
            inManagedObjectContext: self.workerContext)
        
        if let fetchLimit = limit {
            request.fetchLimit = fetchLimit
        }
        
        request.propertiesToFetch = ["persistentID", "lastPlayedDate", "title", "artist"]
        request.resultType = .DictionaryResultType
        
        let sort = NSSortDescriptor(key: "lastPlayedDate", ascending: false)
        request.sortDescriptors = [sort]
        return try? self.workerContext.executeFetchRequest(request)
    }
    
    func lovedControllerWithSortKey(sortKey: String, ascending: Bool, sectionNameKeyPath: String?) -> NSFetchedResultsController {
        
        let request = NSFetchRequest()
        request.entity = NSEntityDescription.entityForName("Song",
            inManagedObjectContext: self.mainQueueContext)
        
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
    
    func playlistsControllerWithSortKey(sortKey sortKey: String!,
        ascending: Bool,
        limit: NSInteger,
        sectionNameKeyPath: String?) -> NSFetchedResultsController {
        let request = NSFetchRequest()
        request.entity = NSEntityDescription.entityForName("Playlist",
            inManagedObjectContext: self.mainQueueContext)
        request.fetchLimit = limit
        
        let sort = NSSortDescriptor(key: sortKey, ascending: ascending)
        request.sortDescriptors = [sort]
        
        return NSFetchedResultsController(fetchRequest: request,
            managedObjectContext: self.mainQueueContext,
            sectionNameKeyPath: sectionNameKeyPath,
            cacheName: nil)
    }
    
    func playlistsControllerWithSectionName(sectionNameKeyPath: String?,
        predicate: NSPredicate?) -> NSFetchedResultsController {
        let request = NSFetchRequest()
        request.entity = NSEntityDescription.entityForName("Playlist",
            inManagedObjectContext: self.mainQueueContext)
        
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
    
    func playlistSongsControllerWithPlaylist(playlist: Playlist,
        sectionNameKeyPath: String?) -> NSFetchedResultsController {
        let request = NSFetchRequest()
        request.entity = NSEntityDescription.entityForName("PlaylistSong",
            inManagedObjectContext: self.mainQueueContext)
        
        let sort = NSSortDescriptor(key: "persistentID", ascending: true)
        request.sortDescriptors = [sort]
        
        return NSFetchedResultsController(fetchRequest: request,
            managedObjectContext: self.mainQueueContext,
            sectionNameKeyPath: sectionNameKeyPath,
            cacheName: nil)
    }
    
    func updatePlaylistSongOrder(playlistsongSource: Playlist,
        sectionNameKeyPath: String?) -> NSFetchedResultsController {
        let request = NSFetchRequest()
        request.entity = NSEntityDescription.entityForName("PlaylistSong",
            inManagedObjectContext: self.mainQueueContext)
        
        let sort = NSSortDescriptor(key: "persistentID", ascending: true)
        request.sortDescriptors = [sort]
            
        return NSFetchedResultsController(fetchRequest: request,
            managedObjectContext: self.mainQueueContext,
            sectionNameKeyPath: sectionNameKeyPath,
            cacheName: nil)
    }
    
    func deletePlaylistWithPlaylist(playlist: Playlist, completion: (error: NSErrorPointer?) -> ()) {
        
        self.mainQueueContext.performBlock { () -> Void in
            var error: NSError?
            let object: NSManagedObject?
            do {
                object = try self.mainQueueContext.existingObjectWithID(playlist.objectID)
            } catch let error1 as NSError {
                error = error1
                object = nil
            } catch {
                fatalError()
            }
            
            if error == nil {
                self.mainQueueContext.deleteObject(object!)
            }
                        
            self.saveDatastoreWithCompletion { (error) -> () in
                if error != nil {
                    completion(error: error)
                } else {
                    completion(error: nil)
                }
            }
        }
    }
    
    // MARK: Fetching
    
    // MARK: Saving
    
    func saveDatastoreWithCompletion(completion: (error: NSErrorPointer) -> ()) {
        let totalStartTime = NSDate()
        self.workerContext.performBlock { () -> Void in
            let error = NSErrorPointer()
            var startTime = NSDate()
            do {
                try self.workerContext.save()
            } catch let error1 as NSError {
                error.memory = error1
            } catch {
                fatalError()
            }
            
            var endTime: NSDate!
            var executionTime: NSTimeInterval!
            
            if error == nil {
                endTime = NSDate()
                executionTime = endTime.timeIntervalSinceDate(startTime)
                NSLog("workerContext saveStore executionTime = %f", (executionTime * 1000));
                
                startTime = NSDate()
                self.mainQueueContext.performBlockAndWait({ () -> Void in
                    do {
                        try self.mainQueueContext.save()
                    } catch let error1 as NSError {
                        error.memory = error1
                    } catch {
                        fatalError()
                    }
                })
                
                if error == nil {
                    endTime = NSDate()
                    executionTime = endTime.timeIntervalSinceDate(startTime)
                    
                    NSLog("mainQueueContext saveStore executionTime = %f",
                    (executionTime * 1000));
                    
                    startTime = NSDate()
                    self.saveContext.performBlockAndWait({ () -> Void in
                        do {
                            try self.saveContext.save()
                        } catch { }
                    })
                }
            }
            
            endTime = NSDate()
            executionTime = endTime.timeIntervalSinceDate(startTime)
            NSLog("workerContext saveStore executionTime = %f", (executionTime * 1000));
            
            let totalEndTime = NSDate()
            executionTime = totalEndTime.timeIntervalSinceDate(totalStartTime)
            NSLog("Total Time saveStore executionTime = %f", (executionTime * 1000));

            completion(error: error)
        }
    }
    
    private func clearCache() {
        NSFetchedResultsController.deleteCacheWithName(nil)
    }
    
    private func deleteAllObjectsInStoreWithCompletion(completion: (error: NSError?) -> ()) {
        clearCache()
        
        self.mainQueueContext.lock()
        self.workerContext.lock()
        
        self.mainQueueContext.reset()
        self.workerContext.reset()
        
        
        if let storeCoordinator = self.mainQueueContext.persistentStoreCoordinator {
            if let store = storeCoordinator.persistentStores.first {
                let storeURL = storeCoordinator.URLForPersistentStore(store)
                
                do {
                    try storeCoordinator.removePersistentStore(store)
                    do {
                        try NSFileManager.defaultManager().removeItemAtURL(storeURL)
                    } catch { }
                } catch { }
                
                do {
                    try persistentStoreCoordinator.addPersistentStoreWithType(NSSQLiteStoreType,
                        configuration: nil,
                        URL: storeURL,
                        options: nil)
                    self.workerContext.unlock()
                    self.mainQueueContext.unlock()
                    completion(error: nil)
                } catch {}
            }
        }
    }
}