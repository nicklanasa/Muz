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
        
        let context = self.workerContext
        
        context.performBlock { () -> Void in
            let startTime = NSDate()
            
            var request = NSFetchRequest(entityName: "Song")
            
            var addedSongs = NSMutableArray(capacity: songs.count)
            
            for item in songs {
                if let song = item as? MPMediaItem {
                    let songTitle = song.title
                    
                    request.predicate = NSPredicate(format: "(title == %@)", songTitle)
                    let error = NSErrorPointer()
                    let result = context.executeFetchRequest(request, error: error)
                    
                    if result?.count > 0 {
                        // Update
                        NSLog("%@ already exists", songTitle)
                        //break
                    } else {
                        let newSong: Song = NSEntityDescription.insertNewObjectForEntityForName("Song", inManagedObjectContext: self.workerContext) as Song
                        newSong.parseItem(song)

                        addedSongs.addObject(newSong)
                    }
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
        
        /*
        return NSFetchedResultsController(fetchRequest: request,
            managedObjectContext: self.mainQueueContext,
            sectionNameKeyPath: sectionNameKeyPath,
            cacheName: nil)
        */
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