//
//  EventManager.swift
//  Desman iOS Sample
//
//  Created by Matteo Gavagnin on 19/10/15.
//  Copyright © 2015 DIMENSION S.r.l. All rights reserved.
//

import Foundation
import CoreData

public let D = EventManager.sharedInstance

@objc public enum Serialization : Int {
    case None
    case UserDefaults
    case CoreData
}

@objc public enum Swizzle : Int {
    case ViewWillAppear
    case ViewDidAppear
    case ViewWillDisappear
}

public class EventManager : NSObject {
    var lastSync : NSDate?
    var upload = false
    var shouldLog = false
    public var consoleLog = false
    public var swizzles = [Swizzle]()
    
    public var limit = 100
    public var timeInterval = 1.0 {
        didSet {
            if timeInterval < 0.25 {
                timeInterval = 0.25
            }
            dispatch_async(dispatch_get_main_queue()) {
                self.timer?.invalidate()
                self.timer = NSTimer.scheduledTimerWithTimeInterval(self.timeInterval, target: self, selector: Selector("processEvents"), userInfo: nil, repeats: true)
            }
        }
    }
    var timer : NSTimer?
    var eventsQueue = [Event]()
    var type = Serialization.None
    
    /**
    A shared instance of `EventManager`.
    */
    static public let sharedInstance = EventManager()

    // Only Desman can set the property or change its objects, but doing so we can make it observable to KVO
    dynamic private(set) public var events = [Event]()
    dynamic internal(set) public var sentEvents = [Event]()
    
    public func takeOff(baseURL: NSURL, appKey: String, serialization: Serialization) {
        self.type = serialization
        self.upload = true
        UploadManager.sharedInstance.takeOff(baseURL, appKey: appKey)
        deserializeEvents()
        
        scheduleProcessTimer()
        
        // We immediately upload app icon and its name
        // TODO: optimize querying the remote server if the app exists, if it doesn't, upload name and icon
        self.forceLog(AppInfo())
    }
    
    public func startLogging() {
        shouldLog = true
        self.logType(Application.LogEnable)
    }
    
    public func stopLogging() {
        self.logType(Application.LogDisable)
        self.processEvents()
        shouldLog = false
    }
    
    public func purgeLogs() {
        self.events.removeAll()
        self.serializeEvents()
        // TODO: remove every online log linked to this device and user
    }
    
    func scheduleProcessTimer() {
        dispatch_async(dispatch_get_main_queue()) {
            if let timer = self.timer {
                timer.invalidate()
            }
            self.timer = NSTimer.scheduledTimerWithTimeInterval(self.timeInterval, target: self, selector: Selector("processEvents"), userInfo: nil, repeats: true)
        }
    }
    
    public func takeOff(serialization: Serialization) {
        self.type = serialization
        deserializeEvents()
        scheduleProcessTimer()
        // TODO: support other databases
    }
    
    public func log(event: Event){
        if shouldLog {
            self.eventsQueue.append(event)
            if type == .CoreData {
                event.saveCDEvent()
            }
            if consoleLog {
                print(event.description)
            }
        }
    }
    
    func forceLog(event: Event){
        self.eventsQueue.append(event)
        if type == .CoreData {
            event.saveCDEvent()
        }
        if consoleLog {
            print(event.description)
        }
    }
    
    public func logType(type: Type){
        if shouldLog {
            let event = Event(type)
            self.eventsQueue.append(event)
            if self.type == .CoreData {
                event.saveCDEvent()
            }
            if consoleLog {
                print(event.description)
            }
        }
    }
    
    public func log(type: Type, payload: [String : Coding]){
        if shouldLog {
            let event = Event(type: type, payload: payload)
            self.eventsQueue.append(event)
            if self.type == .CoreData {
                event.saveCDEvent()
            }
            if consoleLog {
                print(event.description)
            }
        }
    }
    
    func processEvents() {
        guard eventsQueue.count > 0 else  {
            // We only need to upload events already avaiable but not sent.
            UploadManager.sharedInstance.sendEvents(self.events)
            return
        }
        
        self.events.appendContentsOf(eventsQueue)
        
        var sortedEvents = self.events.sort{ $0.timestamp.compare($1.timestamp) == NSComparisonResult.OrderedDescending }
        
        if sortedEvents.count > self.limit {
            sortedEvents.removeRange(self.limit..<sortedEvents.count)
        }
        
        eventsQueue.removeAll()
        self.events = sortedEvents
        
        if self.upload {
            self.sentEvents.removeAll()
            UploadManager.sharedInstance.sendEvents(self.events)
        }
        
        self.serializeEvents()
    }
    
    func serializeEvents() {
        let sortedEvents = events.sort{ $0.timestamp.compare($1.timestamp) == NSComparisonResult.OrderedDescending }
        guard sortedEvents.count > 0 else  {
            return
        }
        if type == .UserDefaults {
            let eventsData = NSKeyedArchiver.archivedDataWithRootObject(sortedEvents)
            let defaults = NSUserDefaults.standardUserDefaults()
            defaults.setObject(eventsData, forKey: "events")
            defaults.synchronize()
        }
    }
    
    public func resetEvents() {
        self.events.removeAll()
    }
    
    func deserializeEvents() {
        if type == .UserDefaults {
            let defaults = NSUserDefaults.standardUserDefaults()
            if let eventsData = defaults.objectForKey("events") as? NSData {
                if let events = NSKeyedUnarchiver.unarchiveObjectWithData(eventsData) as? [Event] {
                    self.eventsQueue.appendContentsOf(events)
                }
            }
        } else if type == .CoreData {
            let request: NSFetchRequest = NSFetchRequest(entityName: "CDEvent")
            if let fetchedEvents = CoreDataSerializerManager.sharedInstance.executeFetchRequest(request) {
                let mappedEvents = fetchedEvents.map{Event(cdevent: $0 as! CDEvent)}
                self.eventsQueue.appendContentsOf(mappedEvents)
            }
        }
    }
    
    public func uploadEvents() {
        UploadManager.sharedInstance.sendEvents(events)
    }
}