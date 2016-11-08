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
    
    func event(_ uuidString: String) -> CDEvent {
        let request : NSFetchRequest<NSFetchRequestResult> = NSFetchRequest()
        request.entity = NSEntityDescription.entity(forEntityName: "CDEvent", in: self.managedObjectContext)
        request.predicate = NSPredicate(format: "uuid = %@", uuidString)
        
        if let events = executeFetchRequest(request) as? [CDEvent], let event = events.last {
            return event
        } else {
            return NSEntityDescription.insertNewObject(forEntityName: "CDEvent", into: self.managedObjectContext) as! CDEvent
        }
    }
    
    var managedObjectContext: NSManagedObjectContext{
        if Thread.isMainThread {
            if (_managedObjectContext == nil) {
                let coordinator = self.persistentStoreCoordinator
                _managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
                _managedObjectContext!.persistentStoreCoordinator = coordinator
                
                return _managedObjectContext!
            }
        } else {
            
            var threadContext : NSManagedObjectContext? = Thread.current.threadDictionary["NSManagedObjectContext"] as? NSManagedObjectContext;
            if threadContext == nil {
                if (_managedObjectContext == nil) {
                    let coordinator = self.persistentStoreCoordinator
                    _managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
                    _managedObjectContext!.persistentStoreCoordinator = coordinator
                }

                threadContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
                threadContext!.parent = _managedObjectContext
                if #available(iOS 8.0, *) {
                    threadContext!.name = Thread.current.description
                } else {
                    // Fallback on earlier versions
                }
                
                Thread.current.threadDictionary["NSManagedObjectContext"] = threadContext
                
                NotificationCenter.default.addObserver(self, selector:#selector(CoreDataSerializerManager.contextWillSave(_:)) , name: NSNotification.Name.NSManagedObjectContextWillSave, object: threadContext)
            }
            return threadContext!;
        }
        
        return _managedObjectContext!
    }
    
    // Returns the managed object model for the application.
    // If the model doesn't already exist, it is created from the application's model.
    var managedObjectModel: NSManagedObjectModel {
        if (_managedObjectModel == nil) {
            let modelURL = Bundle(for: CoreDataSerializerManager.self).url(forResource: kModmName, withExtension: "momd")
            _managedObjectModel = NSManagedObjectModel(contentsOf: modelURL!)
        }
        return _managedObjectModel!
    }
    
    // Returns the persistent store coordinator for the application.
    // If the coordinator doesn't already exist, it is created and the application's store added to it.
    var persistentStoreCoordinator: NSPersistentStoreCoordinator {
        if (_persistentStoreCoordinator == nil) {
            let storeURL = applicationLibraryDirectory.appendingPathComponent(kStoreName)
            _persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
            do {
                try _persistentStoreCoordinator!.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: storeURL, options: self.databaseOptions())
            } catch let error {
                print("Desman: cannot add CoreData persistent store \(error)")
            }
        }
        return _persistentStoreCoordinator!
    }
    
    // #pragma mark - fetches
    
    func executeFetchRequest(_ request:NSFetchRequest<NSFetchRequestResult>)-> Array<AnyObject>?{
        
        var results:Array<AnyObject>?
        self.managedObjectContext.performAndWait {
            do {
                results = try self.managedObjectContext.fetch(request)
            } catch let error {
                print("Desman: warning cannot fetch from Core Data \(error)")
            }
        }
        return results
        
    }
    
    func executeFetchRequest(_ request:NSFetchRequest<NSFetchRequestResult>, completionHandler:@escaping (_ results: Array<NSFetchRequestResult>?) -> Void)-> (){
        
        self.managedObjectContext.perform{
            var results:Array<AnyObject>?
            
            do {
                results = try self.managedObjectContext.fetch(request)
            } catch let error {
                print("Desman: warning cannot fetch from Core Data \(error)")
            }
            
            completionHandler(results as? Array<NSFetchRequestResult>)
        }
        
    }
    
    // #pragma mark - save methods
    
    func save() {
        let context:NSManagedObjectContext = self.managedObjectContext;
        if context.hasChanges {
            
            context.performAndWait{
                do {
                    try context.save()
                } catch _ {
                    print("Desman: warning cannot save to Core Data")
                }
                if let parentContext = context.parent {
                    parentContext.performAndWait {
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
    
    func contextWillSave(_ notification:Foundation.Notification){
        
        let context : NSManagedObjectContext! = notification.object as! NSManagedObjectContext
        let insertedObjects = context.insertedObjects
        
        if insertedObjects.count != 0 {
            do {
                try context.obtainPermanentIDs(for: Array(insertedObjects))
            } catch let error {
                print("Desman: warning cannot obtain ids from Core Data \(error)")
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
    
    var applicationLibraryDirectory: URL {
        let urls = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask)
        return urls[urls.endIndex-1] as URL
    }
}
