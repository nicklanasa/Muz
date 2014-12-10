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
    
    func addSongs(songs: NSArray, completion: (success: Bool) -> ()) {
        let addSongsBlock = { () -> Void in
            let context = self.workerContext
            context.performBlock { () -> Void in
                let startTime = NSDate()
                
                var request = NSFetchRequest(entityName: "Song")
                
                var addedSongs = NSMutableArray(capacity: songs.count)
                
                for item in songs {
                    if let song = item as? MPMediaItem {
                        let newSong: Song = NSEntityDescription.insertNewObjectForEntityForName("Song", inManagedObjectContext: self.workerContext) as Song
                        newSong.parseItem(song)
                        addedSongs.addObject(newSong)
                    }
                }
                
                self.saveDatastoreWithCompletion({ (error) -> () in
                    if error != nil {
                        completion(success: false)
                    } else {
                        completion(success: true)
                    }
                    
                    let endTime = NSDate()
                    let executionTime = endTime.timeIntervalSinceDate(startTime)
                    NSLog("addSongs() - executionTime = %f", (executionTime * 1000));
                })
            }
        }
        
        deleteAllObjectsInStoreWithCompletion { (error) -> () in
            if let e = error {
                print(e)
            } else {
                addSongsBlock()
            }
        }
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
    
    func artistsControllerWithSortKey(sortKey: NSString, ascending: Bool, sectionNameKeyPath: NSString?) -> NSFetchedResultsController {
        
        var request = NSFetchRequest()
        request.entity = NSEntityDescription.entityForName("Song",
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
    
    func songsControllerWithSortKey(sortKey: NSString, ascending: Bool, sectionNameKeyPath: NSString?) -> NSFetchedResultsController {
        
        var request = NSFetchRequest()
        request.entity = NSEntityDescription.entityForName("Song",
            inManagedObjectContext: self.mainQueueContext)
        
        var fetchProperties = NSMutableArray()
        
        if let property: AnyObject = request.entity?.propertiesByName["title"] {
            fetchProperties.addObject(property)
            //request.propertiesToGroupBy = [property]
        }
        
        if let artworkProperty: AnyObject = request.entity?.propertiesByName["artwork"] {
            fetchProperties.addObject(artworkProperty)
        }
        
        request.propertiesToFetch = fetchProperties
        request.resultType = NSFetchRequestResultType.DictionaryResultType
        request.returnsDistinctResults = true
                
        var sort = NSSortDescriptor(key: sortKey, ascending: ascending)
        request.sortDescriptors = [sort]
        
        return NSFetchedResultsController(fetchRequest: request,
            managedObjectContext: self.mainQueueContext,
            sectionNameKeyPath: sectionNameKeyPath,
            cacheName: ArtistsCacheName)
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