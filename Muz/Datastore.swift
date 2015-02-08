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
        
        let storeUrlString = NSString(format: "%@.sqlite", self.storeName)
        let paths = NSFileManager.defaultManager().URLsForDirectory(NSSearchPathDirectory.DocumentDirectory, inDomains: NSSearchPathDomainMask.UserDomainMask)
        if let documentsURL = paths.last as? NSURL {
            let storeURL = documentsURL.URLByAppendingPathComponent(storeUrlString)
            self.persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
            
            var error: NSErrorPointer = nil
            
            if self.persistentStoreCoordinator.addPersistentStoreWithType(NSSQLiteStoreType,
                configuration: nil,
                URL: storeURL,
                options: nil,
                error: error) == false {
                    assert(true, "Unable to get persistentStoreCoordinator...")
            }
            
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
    
    func addSongs(songs: NSArray, completion: (addedItems: [AnyObject], error: NSErrorPointer) -> ()) {
        let context = self.mainQueueContext
        context.performBlock { () -> Void in
            let startTime = NSDate()
            
            var request = NSFetchRequest(entityName: "Song")
            
            var addedSongs = NSMutableArray(capacity: songs.count)
            var existedSongs = NSMutableArray(capacity: songs.count)
            
            var count = 0
            
            for item in songs {
                count++
                if let song = item as? MPMediaItem {
                    
                    var error: NSError?
                    
                    if let artist = song.artist {
                        
                        let predicate = NSPredicate(format: "title = %@ AND artist = %@", song.title, song.artist)
                        request.fetchLimit = 1
                        request.predicate = predicate
                        let results = context.executeFetchRequest(request, error: &error)
                        
                        var managedSong: Song!
                        if results?.count > 0 {
                            managedSong = results?[0] as Song
                        } else {
                            managedSong = NSEntityDescription.insertNewObjectForEntityForName("Song",
                                inManagedObjectContext: context) as Song
                            managedSong.parseItem(song)
                        }
                        
                        addedSongs.addObject(managedSong)
                    }
                }
            }
            
            self.saveDatastoreWithCompletion({ (error) -> () in
                let endTime = NSDate()
                let executionTime = endTime.timeIntervalSinceDate(startTime)
                NSLog("addSongs() - executionTime = %f\n addedSongs count: %d\n existedSongs count: %d", (executionTime * 1000), addedSongs.count, existedSongs.count);
                
                if error != nil {
                    LocalyticsSession.shared().tagEvent("Unabled to save added songs. addSongs()")
                } else {
                    LocalyticsSession.shared().tagEvent("Added songs")
                }
                
                completion(addedItems: addedSongs, error: error)
            })
        }
    }
    
    /**
    Adds artists to the datastore.
    
    :param: artists    The artists you want to add.
    :param: completion The completion block called at the end of the execution.
    */
    func addArtists(artists: NSArray, completion: (addedItems: [AnyObject], error: NSErrorPointer) -> ()) {
        self.mainQueueContext.performBlock { () -> Void in
           
            let startTime = NSDate()
            var request = NSFetchRequest(entityName: "Artist")
            var addedArtists = NSMutableArray(capacity: artists.count)
            
            artists.enumerateObjectsUsingBlock({ (artist, idx, stop) -> Void in
                if let item = artist as? MPMediaItem {
                    
                    var error: NSError?
                    
                    if let artistName = item.artist {
                        
                        let predicate = NSPredicate(format: "name = %@", artistName)
                        request.fetchLimit = 1
                        request.predicate = predicate
                        let results = self.mainQueueContext.executeFetchRequest(request, error: &error)
                        
                        var managedArtist: Artist!
                        if results?.count > 0 {
                            managedArtist = results?[0] as Artist
                        } else {
                            managedArtist = NSEntityDescription.insertNewObjectForEntityForName("Artist",
                                inManagedObjectContext: self.mainQueueContext) as Artist
                        }
                        
                        managedArtist.parseItem(item)
                        
                        // Add albums
                        self.addAlbumForItem(item: item, artist: managedArtist)
                        
                        addedArtists.addObject(managedArtist)
                    }
                }
            })

            self.saveDatastoreWithCompletion({ (error) -> () in
                let endTime = NSDate()
                let executionTime = endTime.timeIntervalSinceDate(startTime)
                NSLog("addArtists() - executionTime = %f\n addedSongs count: %d\n existedSongs count: %d", (executionTime * 1000), addedArtists.count);
                
                if error != nil {
                    LocalyticsSession.shared().tagEvent("Unabled to save added artists.")
                } else {
                    LocalyticsSession.shared().tagEvent("Saved artists.")
                }
                
                completion(addedItems: addedArtists, error: error)
            })
        }
    }
    
    func addAlbumsForArtist(#artist: Artist, albums: NSArray, completion: (addedItems: [AnyObject], error: NSErrorPointer) -> ()) {
        self.workerContext.performBlock { () -> Void in
            
            let startTime = NSDate()
            var request = NSFetchRequest(entityName: "Album")
            var addedAlbums = NSMutableArray(capacity: albums.count)
            
            print(albums)
            
            albums.enumerateObjectsUsingBlock({ (album, idx, stop) -> Void in
                if let item = album as? MPMediaItem {
                    
                    var error: NSError?
                    
                    if let title = item.albumTitle {
                        
                        let predicate = NSPredicate(format: "title = %@", title)
                        request.fetchLimit = 1
                        request.predicate = predicate
                        let results = self.workerContext.executeFetchRequest(request, error: &error)
                        
                        var managedAlbum: Album!
                        if results?.count > 0 {
                            managedAlbum = results?[0] as Album
                        } else {
                            managedAlbum = NSEntityDescription.insertNewObjectForEntityForName("Album",
                                inManagedObjectContext: self.workerContext) as Album
                            addedAlbums.addObject(managedAlbum)
                        }
                        
                        managedAlbum.parseItem(item)
                        self.addSongForItem(item: item, album: managedAlbum)
                        
                        artist.addAlbum(managedAlbum)
                    }
                }

            })
            
            artist.modifiedDate = NSDate()
            
            self.saveDatastoreWithCompletion({ (error) -> () in
                let endTime = NSDate()
                let executionTime = endTime.timeIntervalSinceDate(startTime)
                NSLog("addAlbums() - executionTime = %f\n addAlbums count: %d\n existedSongs count: %d", (executionTime * 1000), addedAlbums.count);
                
                if error != nil {
                    LocalyticsSession.shared().tagEvent("Unabled to save added ablums.")
                } else {
                    LocalyticsSession.shared().tagEvent("Saved ablums.")
                }
                
                completion(addedItems: addedAlbums, error: error)
            })
        }

    }
    
    /**
    Add album for item.
    
    :param: item The item you want to use to add a new album from.
    
    :returns: The created/existing album or nil.
    */
    func addAlbumForItem(#item: MPMediaItem, artist: Artist) {
        var error: NSError?
        var request = NSFetchRequest(entityName: "Album")
        
        var managedAlbum = NSEntityDescription.insertNewObjectForEntityForName("Album",
            inManagedObjectContext: self.mainQueueContext) as Album
        managedAlbum.parseItem(item)
        managedAlbum.artist = artist
        
        self.addSongForItem(item: item, album: managedAlbum)
    }
    
    func artistForSong(#song: Song) -> Artist? {
        var error: NSError?
        var request = NSFetchRequest(entityName: "Artist")
        let predicate = NSPredicate(format: "name = %@", song.artist)
        request.fetchLimit = 1
        request.predicate = predicate
        let results = self.workerContext.executeFetchRequest(request, error: &error)
        
        var managedArtist: Artist!
        if results?.count > 0 {
            managedArtist = results?[0] as Artist
            return managedArtist
        } else {
            return nil
        }
    }
    
    func artistForSongData(#song: NSDictionary) -> Artist? {
        var error: NSError?
        var request = NSFetchRequest(entityName: "Artist")
        let predicate = NSPredicate(format: "name = %@", song.objectForKey("artist") as NSString)
        request.fetchLimit = 1
        request.predicate = predicate
        let results = self.workerContext.executeFetchRequest(request, error: &error)
        
        var managedArtist: Artist!
        if results?.count > 0 {
            managedArtist = results?[0] as Artist
            return managedArtist
        } else {
            return nil
        }
    }
    
    /**
    Adds a song to an album.
    
    :param: item The song you want to add.
    
    :returns: The added song.
    */
    func addSongForItem(#item: MPMediaItem, album: Album) {
        var error: NSError?
        var request = NSFetchRequest(entityName: "Song")
        var managedSong = NSEntityDescription.insertNewObjectForEntityForName("Song",
            inManagedObjectContext: self.mainQueueContext) as Song
        managedSong.parseItem(item)
        managedSong.album = album
    }
    
    func updateSong(#song: Song, completion: () -> ()) {
        song.lastPlayedDate = NSDate()
        
        self.saveDatastoreWithCompletion({ (error) -> () in
            println("Updated song with new lastPlayedDate: \(song.lastPlayedDate)")
            completion()
        })
    }
    
    func updatePlaylist(#playlist: Playlist, completion: () -> ()) {
        playlist.modifiedDate = NSDate()
        
        self.saveDatastoreWithCompletion({ (error) -> () in
            println("Updated playlist with new modified date: \(playlist.modifiedDate)")
            completion()
        })
    }
    
    func addPlaylists(playlists: [AnyObject], completion: (addedPlaylists: [AnyObject]?) -> ()) {
        
        var error: NSError?

        for playlist in playlists as [MPMediaPlaylist] {
            let addedPlaylist = createPlaylistWithPlaylist(playlist, context: self.mainQueueContext)
        }
        
        self.saveDatastoreWithCompletion({ (error) -> () in
            println("Saved datastore for playlists.")
        })
    }
    
    func createPlaylistWithSimiliarArtists(artist: NSString!, artists: [AnyObject]!,
        fetchLimit: NSInteger,
        name: NSString!,
        playlistType: PlaylistType,
        completion: (addedSongs: [AnyObject]?) -> ()) {
        
        clearCache()
        
        var error: NSError?
        var request = NSFetchRequest(entityName: "Song")
    
        var predicates = NSMutableArray()
        
        let artistPredicate = NSPredicate(format: "(artist contains[cd] %@)", artist)!
        predicates.addObject(artistPredicate)
            
        for artist in artists as [LastFmArtist] {
            println(artist.name)
            let predicate = NSPredicate(format: "(artist contains[cd] %@)", artist.name)!
            predicates.addObject(predicate)
        }
        
        let compoundPredicate = NSCompoundPredicate.orPredicateWithSubpredicates(predicates)
        request.predicate = compoundPredicate
        request.fetchLimit = fetchLimit
        
        let results = self.workerContext.executeFetchRequest(request, error: &error)
        
        if results?.count > 0 {
            
            // Create smart playlist based on artists.
            let playlist = NSEntityDescription.insertNewObjectForEntityForName("Playlist",
                inManagedObjectContext: self.workerContext) as Playlist
            playlist.name = name
            playlist.playlistType = NSNumber(unsignedLong: playlistType.rawValue)
            playlist.persistentID = ""
            
            // Create PlaySongs
            var playlistSongs = NSMutableSet()
            var order = 0
            
            for song in results as [Song] {
                let playlistSong = NSEntityDescription.insertNewObjectForEntityForName("PlaylistSong",
                    inManagedObjectContext: self.workerContext) as PlaylistSong
                
                playlistSong.parseSong(song, playlist: playlist, order: order)
                playlistSongs.addObject(playlistSong)
                println("Created new playlist song with title: \(song.title)")
                order++
            }
            
            playlist.playlistSongs = playlistSongs
        }
            
        LocalyticsSession.shared().tagEvent("createPlaylistWithSimiliarArtists()")
        
        self.saveDatastoreWithCompletion { (error) -> () in
            if results?.count > 0 {
                completion(addedSongs: results)
            } else {
                completion(addedSongs: nil)
            }
        }
    }
    
    func createPlaylistWithArtist(artist: NSString!,
        name: NSString!,
        playlistType: PlaylistType,
        completion: (addedSongs: [AnyObject]?) -> ()) {
            
        clearCache()
        
        var error: NSError?
        var request = NSFetchRequest(entityName: "Song")
        
        let predicate = NSPredicate(format: "(artist contains[cd] %@)", artist)
        request.predicate = predicate
        
        let results = self.mainQueueContext.executeFetchRequest(request, error: &error)
        
        if results?.count > 0 {
            
            // Create smart playlist based on artists.
            let playlist = NSEntityDescription.insertNewObjectForEntityForName("Playlist",
                inManagedObjectContext: self.mainQueueContext) as Playlist
            playlist.name = name
            playlist.playlistType = NSNumber(unsignedLong: playlistType.rawValue)
            playlist.persistentID = ""
            
            // Create PlaySongs
            var playlistSongs = NSMutableSet()
            var order = 0
            
            for song in results as [Song] {
                let playlistSong = NSEntityDescription.insertNewObjectForEntityForName("PlaylistSong",
                    inManagedObjectContext: self.mainQueueContext) as PlaylistSong
                
                playlistSong.parseSong(song, playlist: playlist, order: order)
                playlistSongs.addObject(playlistSong)
                println("Created new playlist song with title: \(song.title)")
                order++
            }
            
            playlist.playlistSongs = playlistSongs
        }
            
        LocalyticsSession.shared().tagEvent("createPlaylistWithArtist()")
        
        self.saveDatastoreWithCompletion { (error) -> () in
            if results?.count > 0 {
                completion(addedSongs: results)
            } else {
                completion(addedSongs: nil)
            }
        }
    }
    
    // TODO: Change this to use worker context.
    func addArtistSongsToPlaylist(playlist: Playlist, artist: NSString!,
        completion: (addedSongs: [AnyObject]?) -> ()) {
            
            clearCache()
            
            var error: NSError?
            var request = NSFetchRequest(entityName: "Song")
            
            let predicate = NSPredicate(format: "(artist contains[cd] %@)", artist)
            request.predicate = predicate
            
            let results = self.mainQueueContext.executeFetchRequest(request, error: &error)
            
            if results?.count > 0 {
                // Create PlaySongs
                var playlistSongs = NSMutableSet()
                var order = playlist.playlistSongs.count
                
                for song in results as [Song] {
                    let playlistSong = NSEntityDescription.insertNewObjectForEntityForName("PlaylistSong",
                        inManagedObjectContext: self.mainQueueContext) as PlaylistSong
                    
                    playlistSong.parseSong(song, playlist: playlist, order: order)
                    playlistSongs.addObject(playlistSong)
                    println("Created new playlist song with title: \(song.title)")
                    order++
                }
                
                let combinedSongs = NSMutableSet(set: playlist.playlistSongs)
                combinedSongs.addObjectsFromArray(playlistSongs.allObjects)
                playlist.playlistSongs = combinedSongs
            }
            
            LocalyticsSession.shared().tagEvent("addArtistSongsToPlaylist()")
            
            self.saveDatastoreWithCompletion { (error) -> () in
                if results?.count > 0 {
                    completion(addedSongs: results)
                } else {
                    completion(addedSongs: nil)
                }
            }
    }
    
    func createPlaylistWithSongs(name: NSString, songs: [AnyObject]!, completion: (addedSongs: [AnyObject]?) -> ()) {
        let playlist = NSEntityDescription.insertNewObjectForEntityForName("Playlist",
            inManagedObjectContext: self.mainQueueContext) as Playlist
        playlist.name = name
        playlist.playlistType = NSNumber(unsignedLong: PlaylistType.None.rawValue)
        playlist.persistentID = ""
        
        var playlistSongs = NSMutableSet()
        var order = 0
        
        for song in songs as [Song] {
            let playlistSong = NSEntityDescription.insertNewObjectForEntityForName("PlaylistSong",
                inManagedObjectContext: self.mainQueueContext) as PlaylistSong
            
            playlistSong.parseSong(song, playlist: playlist, order: order)
            playlistSongs.addObject(playlistSong)
            println("Created new playlist song with title: \(song.title)")
            order++
        }
        
        playlist.playlistSongs = playlistSongs
        
        LocalyticsSession.shared().tagEvent("createPlaylistWithItems()")
        
        self.saveDatastoreWithCompletion { (error) -> () in
            completion(addedSongs: playlistSongs.allObjects)
        }
    }
    
    func addSongsToPlaylist(songs: [AnyObject]!, playlist: Playlist, completion: (addedSongs: [AnyObject]?) -> ()) {
        var playlistSongs = NSMutableSet(set: playlist.playlistSongs)
        var order = playlistSongs.count
        
        for song in songs as [Song] {
            let playlistSong = NSEntityDescription.insertNewObjectForEntityForName("PlaylistSong",
                inManagedObjectContext: self.mainQueueContext) as PlaylistSong
            
            playlistSong.parseSong(song, playlist: playlist, order: order)
            playlistSongs.addObject(playlistSong)
            println("Created new playlist song with title: \(song.title)")
            order++
        }
        
        playlist.playlistSongs = playlistSongs
        
        self.saveDatastoreWithCompletion { (error) -> () in
            completion(addedSongs: playlistSongs.allObjects)
        }
    }
    
    func createEmptyPlaylistWithName(name: NSString, playlistType: PlaylistType, completion: () -> ()) {
        let playlist = NSEntityDescription.insertNewObjectForEntityForName("Playlist",
            inManagedObjectContext: self.mainQueueContext) as Playlist
        playlist.name = name
        playlist.playlistType = NSNumber(unsignedLong: playlistType.rawValue)
        playlist.persistentID = ""
        
        LocalyticsSession.shared().tagEvent("createEmptyPlaylistWithName()")
        
        self.saveDatastoreWithCompletion { (error) -> () in
            completion()
        } 
    }
    
    private func createPlaylistWithPlaylist(playlist: MPMediaPlaylist, context: NSManagedObjectContext) -> Playlist {
        var error: NSError?
        
        var request = NSFetchRequest(entityName: "Playlist")
        let predicate = NSPredicate(format: "persistentID = %@", String(playlist.persistentID))
        request.predicate = predicate
        let results = context.executeFetchRequest(request, error: &error)
        
        if results?.count > 0 {
            // Update
            var existingPlaylist = results?[0] as Playlist
            existingPlaylist.parsePlaylist(playlist)
            return existingPlaylist
        } else {
            let newPlaylist = NSEntityDescription.insertNewObjectForEntityForName("Playlist",
                inManagedObjectContext: context) as Playlist
            
            newPlaylist.parsePlaylist(playlist)
            
            println("Created playlist with name: \(newPlaylist.name) and type: \(newPlaylist.playlistType.integerValue)")
            
            return newPlaylist
        }
    }
    
    private func addSongToPlaylist(playlist: Playlist, song: Song, originalPlaylist: MPMediaPlaylist?, context: NSManagedObjectContext) {
        
        var songs = NSMutableSet()
        var error: NSError?
        var request = NSFetchRequest(entityName: "PlaylistSong")
        let predicate = NSPredicate(format: "persistentID = %@", playlist.persistentID)
        request.fetchLimit = 1
        let results = context.executeFetchRequest(request, error: &error)
        
        if results?.count > 0 {
            // Update
            var playlistSong = results?[0] as PlaylistSong
            playlistSong.updatePlaylistSong(song, playlist: playlist, originalPlaylist: originalPlaylist)
            
            songs.addObject(playlistSong)
        } else {
            let newPlaylistSong = NSEntityDescription.insertNewObjectForEntityForName("PlaylistSong",
                inManagedObjectContext: context) as PlaylistSong
            newPlaylistSong.parsePlaylistSong(song, playlist: playlist, originalPlaylist: originalPlaylist)
            
            songs.addObject(newPlaylistSong)
        }
    }
    
    func songForSongName(songName: String, artist: NSString) -> Song? {
        var request = NSFetchRequest()
        request.entity = NSEntityDescription.entityForName("Song",
            inManagedObjectContext: self.mainQueueContext)
        
        request.fetchLimit = 1
        
        let predicate = NSPredicate(format: "title = %@ AND artist = %@", songName, artist)
        request.predicate = predicate
        
        var error = NSErrorPointer()
        let results = self.mainQueueContext.executeFetchRequest(request, error: error)
        
        if results?.count > 0 {
            if let song = results?[0] as? Song {
                return song
            }
            
            return nil
        }
        return nil
    }
    
    // MARK: NSFetchedResultsControllers
    
    func artistsWithSortKey(sortKey: NSString, ascending: Bool, sectionNameKeyPath: NSString?) -> [AnyObject]? {
        var request = NSFetchRequest()
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
        
        var sort = NSSortDescriptor(key: sortKey, ascending: ascending)
        request.sortDescriptors = [sort]
        
        var error = NSErrorPointer()
        return self.mainQueueContext.executeFetchRequest(request, error: error)
    }
    
    func artistsController(predicate: NSPredicate?, sortKey: NSString, ascending: Bool, sectionNameKeyPath: NSString?) -> NSFetchedResultsController {
        
        var request = NSFetchRequest()
        request.entity = NSEntityDescription.entityForName("Artist",
            inManagedObjectContext: self.mainQueueContext)
        
        if let artistPredicate = predicate {
            request.predicate = artistPredicate
        }

        var sort = NSSortDescriptor(key: sortKey, ascending: ascending)
        request.sortDescriptors = [sort]
        
        return NSFetchedResultsController(fetchRequest: request,
        managedObjectContext: self.mainQueueContext,
        sectionNameKeyPath: sectionNameKeyPath,
        cacheName: nil)
    }
    
    func plsylistSsongsControllerWithSortKey(sortKey: NSString, ascending: Bool, sectionNameKeyPath: NSString?) -> NSFetchedResultsController {
        
        var request = NSFetchRequest()
        request.entity = NSEntityDescription.entityForName("PlaylistSong",
            inManagedObjectContext: self.mainQueueContext)
        
        let predicate = NSPredicate(format: "(artist.length > 0)")
        request.predicate = predicate
        
        var properties = NSMutableArray()
        
        if let artistProperty: AnyObject = request.entity?.propertiesByName["artist"] {
            properties.addObject(artistProperty)
        }
        
        request.propertiesToGroupBy = properties
        request.propertiesToFetch = properties
        request.returnsDistinctResults = true
        request.resultType = NSFetchRequestResultType.DictionaryResultType
        
        var sort = NSSortDescriptor(key: sortKey, ascending: ascending)
        request.sortDescriptors = [sort]
        
        return NSFetchedResultsController(fetchRequest: request,
            managedObjectContext: self.mainQueueContext,
            sectionNameKeyPath: sectionNameKeyPath,
            cacheName: ArtistsCacheName)
    }
    
    func artistsAlbumsControllerWithSortKey(artist: Artist,
        sortKey: NSString,
        ascending: Bool,
        sectionNameKeyPath: NSString?) -> NSFetchedResultsController {
        
        var request = NSFetchRequest()
        request.entity = NSEntityDescription.entityForName("Album",
            inManagedObjectContext: self.mainQueueContext)
        
        let predicate = NSPredicate(format: "artist like %@", artist)
        request.predicate = predicate
        
        var groupBy = NSMutableArray()
        var fetch = NSMutableArray()
        
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
        
        request.propertiesToGroupBy = groupBy
        request.propertiesToFetch = fetch
        request.returnsDistinctResults = true
        request.resultType = NSFetchRequestResultType.DictionaryResultType
        
        var sort = NSSortDescriptor(key: sortKey, ascending: ascending)
        var sortTrackNumber = NSSortDescriptor(key: "albumTrackNumber", ascending: true)
        request.sortDescriptors = [sort, sortTrackNumber]
        
        return NSFetchedResultsController(fetchRequest: request,
            managedObjectContext: self.mainQueueContext,
            sectionNameKeyPath: sectionNameKeyPath,
            cacheName: ArtistsCacheName)
    }
    
    func songsControllerWithSortKey(sortKey: NSString,
        limit: NSInteger?,
        ascending: Bool,
        sectionNameKeyPath: NSString?) -> NSFetchedResultsController {
        
        var request = NSFetchRequest()
        
        if let fetchLimit = limit {
            request.fetchLimit = fetchLimit
        }
        
        request.entity = NSEntityDescription.entityForName("Song",
            inManagedObjectContext: self.mainQueueContext)
        
        var sort = NSSortDescriptor(key: sortKey, ascending: ascending)
        request.sortDescriptors = [sort]
        
        return NSFetchedResultsController(fetchRequest: request,
            managedObjectContext: self.mainQueueContext,
            sectionNameKeyPath: sectionNameKeyPath,
            cacheName: nil)
    }
    
    func distinctArtistSongsWithSortKey(sortKey: NSString,
        limit: NSInteger?,
        ascending: Bool) -> NSArray?
    {
        
        var request = NSFetchRequest()
        request.entity = NSEntityDescription.entityForName("Song",
            inManagedObjectContext: self.workerContext)
        
        if let fetchLimit = limit {
            request.fetchLimit = fetchLimit
        }
        
        request.propertiesToFetch = ["artist"]
        request.returnsDistinctResults = true
        request.resultType = .DictionaryResultType
        
        let results = self.workerContext.executeFetchRequest(request, error: nil)
        
        if results?.count > 0 {
            var predicates = NSMutableArray()
            for artist in results as [NSDictionary] {
                predicates.addObject(NSPredicate(format: "artist = %@", artist.objectForKey("artist") as NSString)!)
            }
            
            var compoundPredicate = NSCompoundPredicate(type: .OrPredicateType, subpredicates: predicates)
            request.predicate = compoundPredicate
            
            request.propertiesToFetch = ["artist", "title", "persistentID"]
            
            var sort = NSSortDescriptor(key: sortKey, ascending: ascending)
            request.sortDescriptors = [sort]
            
            return self.workerContext.executeFetchRequest(request, error: nil)
        }
        
        return nil
    }
    
    func lovedControllerWithSortKey(sortKey: NSString, ascending: Bool, sectionNameKeyPath: NSString?) -> NSFetchedResultsController {
        
        var request = NSFetchRequest()
        request.entity = NSEntityDescription.entityForName("Song",
            inManagedObjectContext: self.mainQueueContext)
        
        var predicate = NSPredicate(format: "rating > 3")
        request.predicate = predicate
        
        request.returnsDistinctResults = true
        
        var sort = NSSortDescriptor(key: sortKey, ascending: ascending)
        request.sortDescriptors = [sort]
        
        return NSFetchedResultsController(fetchRequest: request,
            managedObjectContext: self.mainQueueContext,
            sectionNameKeyPath: sectionNameKeyPath,
            cacheName: ArtistsCacheName)
    }
    
    func playlistsControllerWithSortKey(#sortKey: NSString!,
        ascending: Bool,
        limit: NSInteger,
        sectionNameKeyPath: NSString?) -> NSFetchedResultsController {
        var request = NSFetchRequest()
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
    
    func playlistsControllerWithSectionName(sectionNameKeyPath: NSString?,
        predicate: NSPredicate?) -> NSFetchedResultsController {
        var request = NSFetchRequest()
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
        sectionNameKeyPath: NSString?) -> NSFetchedResultsController {
        var request = NSFetchRequest()
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
        sectionNameKeyPath: NSString?) -> NSFetchedResultsController {
        var request = NSFetchRequest()
        request.entity = NSEntityDescription.entityForName("PlaylistSong",
            inManagedObjectContext: self.mainQueueContext)
        
        let sort = NSSortDescriptor(key: "persistentID", ascending: true)
        request.sortDescriptors = [sort]
        
        LocalyticsSession.shared().tagEvent("updatePlaylistSongOrder()")
        
        return NSFetchedResultsController(fetchRequest: request,
            managedObjectContext: self.mainQueueContext,
            sectionNameKeyPath: sectionNameKeyPath,
            cacheName: nil)
    }
    
    func deletePlaylistWithPlaylist(playlist: Playlist, completion: (error: NSErrorPointer?) -> ()) {
        
        self.mainQueueContext.performBlock { () -> Void in
            var error: NSError?
            let object = self.mainQueueContext.existingObjectWithID(playlist.objectID, error: &error)
            
            if error == nil {
                self.mainQueueContext.deleteObject(object!)
            }
            
            LocalyticsSession.shared().tagEvent("deletePlaylistWithPlaylist()")
            
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
            var error = NSErrorPointer()
            var startTime = NSDate()
            self.workerContext.save(error)
            
            var endTime: NSDate!
            var executionTime: NSTimeInterval!
            
            if error == nil {
                endTime = NSDate()
                executionTime = endTime.timeIntervalSinceDate(startTime)
                NSLog("workerContext saveStore executionTime = %f", (executionTime * 1000));
                
                startTime = NSDate()
                self.mainQueueContext.performBlockAndWait({ () -> Void in
                    let success = self.mainQueueContext.save(error)
                })
                
                if error == nil {
                    endTime = NSDate()
                    executionTime = endTime.timeIntervalSinceDate(startTime)
                    
                    NSLog("mainQueueContext saveStore executionTime = %f",
                    (executionTime * 1000));
                    
                    startTime = NSDate()
                    self.saveContext.performBlockAndWait({ () -> Void in
                        let success = self.saveContext.save(error)
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
        
        var error: NSError?
        
        if let storeCoordinator = self.mainQueueContext.persistentStoreCoordinator {
            if let store = storeCoordinator.persistentStores.first as? NSPersistentStore {
                let storeURL = storeCoordinator.URLForPersistentStore(store)
                
                if storeCoordinator.removePersistentStore(store, error: &error) {
                    NSFileManager.defaultManager().removeItemAtURL(storeURL, error: &error)
                }
                
                if let newStore = persistentStoreCoordinator.addPersistentStoreWithType(NSSQLiteStoreType,
                    configuration: nil,
                    URL: storeURL,
                    options: nil,
                    error: &error) {
                    self.workerContext.unlock()
                    self.mainQueueContext.unlock()
                    completion(error: error)
                } else {
                    // TODO: Handling not being about to create new store...
                    completion(error: error)
                }
            }
        }
    }
    
    /**
    Returns a NSFetchedResultsController with all levels.
    
    :param: keyPath A key path on result objects that returns the section name.
    
    :returns: A NSFetchedResultsController with all levels.
    */
//    func levelsControllerWithSectionKeyPath(sectionKeyPath: String?) -> NSFetchedResultsController {
//        let request = NSFetchRequest()
//        let entity = NSEntityDescription.entityForName("Level", inManagedObjectContext: self.mainQueueContext)
//        request.entity = entity
//        
//        let sort = NSSortDescriptor(key: "name", ascending: false)
//        request.sortDescriptors = [sort]
//        
//        return NSFetchedResultsController(fetchRequest: request,
//            managedObjectContext: self.mainQueueContext,
//            sectionNameKeyPath: sectionKeyPath,
//            cacheName: AllLevels)
//    }
}