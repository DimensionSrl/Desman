//
//  CoreDataSerializerManager.swift
//  Desman
//
//  Created by Matteo Gavagnin on 18/11/15.
//  Copyright © 2015 DIMENSION S.r.l. All rights reserved.
//
//  Heaviliy based on https://github.com/mdelamata/CoreDataManager-Swift

import Foundation
import CoreData

class CoreDataSerializerManager: NSObject {
    
    let kStoreName = "Desman.sqlite"
    let kModmName = "Desman"
    
    var _managedObjectContext: NSManagedObjectContext? = nil
    var _managedObjectModel: NSManagedObjectModel? = nil
    var _persistentStoreCoordinator: NSPersistentStoreCoordinator? = nil

    static let sharedInstance = CoreDataSerializerManager()
    
    // #pragma mark - Core Data stack
    
    func event(uuidString: String) -> CDEvent {
        let request = NSFetchRequest()
        request.entity = NSEntityDescription.entityForName("CDEvent", inManagedObjectContext: self.managedObjectContext)
        request.predicate = NSPredicate(format: "uuid = %@", uuidString)
        
        if let events = executeFetchRequest(request) as? [CDEvent], let event = events.last {
            return event
        } else {
            return NSEntityDescription.insertNewObjectForEntityForName("CDEvent", inManagedObjectContext: self.managedObjectContext) as! CDEvent
        }
    }
    
    var managedObjectContext: NSManagedObjectContext{
        if NSThread.isMainThread() {
            if (_managedObjectContext == nil) {
                let coordinator = self.persistentStoreCoordinator
                _managedObjectContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
                _managedObjectContext!.persistentStoreCoordinator = coordinator
                
                return _managedObjectContext!
            }
        } else {
            
            var threadContext : NSManagedObjectContext? = NSThread.currentThread().threadDictionary["NSManagedObjectContext"] as? NSManagedObjectContext;
            if threadContext == nil {
                if (_managedObjectContext == nil) {
                    let coordinator = self.persistentStoreCoordinator
                    _managedObjectContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
                    _managedObjectContext!.persistentStoreCoordinator = coordinator
                }

                threadContext = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
                threadContext!.parentContext = _managedObjectContext
                if #available(iOS 8.0, *) {
                    threadContext!.name = NSThread.currentThread().description
                } else {
                    // Fallback on earlier versions
                }
                
                NSThread.currentThread().threadDictionary["NSManagedObjectContext"] = threadContext
                
                NSNotificationCenter.defaultCenter().addObserver(self, selector:#selector(CoreDataSerializerManager.contextWillSave(_:)) , name: NSManagedObjectContextWillSaveNotification, object: threadContext)
            }
            return threadContext!;
        }
        
        return _managedObjectContext!
    }
    
    // Returns the managed object model for the application.
    // If the model doesn't already exist, it is created from the application's model.
    var managedObjectModel: NSManagedObjectModel {
        if (_managedObjectModel == nil) {
            let modelURL = NSBundle(forClass: CoreDataSerializerManager.self).URLForResource(kModmName, withExtension: "momd")
            _managedObjectModel = NSManagedObjectModel(contentsOfURL: modelURL!)
        }
        return _managedObjectModel!
    }
    
    // Returns the persistent store coordinator for the application.
    // If the coordinator doesn't already exist, it is created and the application's store added to it.
    var persistentStoreCoordinator: NSPersistentStoreCoordinator {
        if (_persistentStoreCoordinator == nil) {
            let storeURL = applicationLibraryDirectory.URLByAppendingPathComponent(kStoreName)
            _persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
            do {
                try _persistentStoreCoordinator!.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: storeURL, options: self.databaseOptions())
            } catch let error {
                print("Desman: cannot add CoreData persistent store \(error)")
            }
        }
        return _persistentStoreCoordinator!
    }
    
    // #pragma mark - fetches
    
    func executeFetchRequest(request:NSFetchRequest)-> Array<AnyObject>?{
        
        var results:Array<AnyObject>?
        self.managedObjectContext.performBlockAndWait {
            do {
                results = try self.managedObjectContext.executeFetchRequest(request)
            } catch let error {
                print("Desman: warning cannot fetch from Core Data \(error)")
            }
        }
        return results
        
    }
    
    func executeFetchRequest(request:NSFetchRequest, completionHandler:(results: Array<AnyObject>?) -> Void)-> (){
        
        self.managedObjectContext.performBlock{
            var results:Array<AnyObject>?
            
            do {
                results = try self.managedObjectContext.executeFetchRequest(request)
            } catch let error {
                print("Desman: warning cannot fetch from Core Data \(error)")
            }
            
            completionHandler(results: results)
        }
        
    }
    
    // #pragma mark - save methods
    
    func save() {
        let context:NSManagedObjectContext = self.managedObjectContext;
        if context.hasChanges {
            
            context.performBlockAndWait{
                do {
                    try context.save()
                } catch _ {
                    print("Desman: warning cannot save to Core Data")
                }
                if let parentContext = context.parentContext {
                    parentContext.performBlockAndWait {
                        do {
                            try parentContext.save()
                        } catch let error {
                            print("Desman: warning cannot save to Core Data \(error)")
                        }
                    }
                }
            }
        }
    }
    
    func contextWillSave(notification:NSNotification){
        
        let context : NSManagedObjectContext! = notification.object as! NSManagedObjectContext
        let insertedObjects : NSSet = context.insertedObjects
        
        if insertedObjects.count != 0 {
            do {
                try context.obtainPermanentIDsForObjects(insertedObjects.allObjects as! [NSManagedObject])
            } catch let error {
                ("Desman: warning cannot obtain ids from Core Data \(error)")
            }
        }
    }
    
    // #pragma mark - Utilities
    
    func databaseOptions() -> Dictionary <String,Bool> {
        var options =  Dictionary<String,Bool>()
        options[NSMigratePersistentStoresAutomaticallyOption] = true
        options[NSInferMappingModelAutomaticallyOption] = true
        return options
    }
    
    var applicationLibraryDirectory: NSURL {
        let urls = NSFileManager.defaultManager().URLsForDirectory(.LibraryDirectory, inDomains: .UserDomainMask)
        return urls[urls.endIndex-1] as NSURL
    }
}