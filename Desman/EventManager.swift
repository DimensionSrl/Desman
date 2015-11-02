//
//  EventManager.swift
//  Desman iOS Sample
//
//  Created by Matteo Gavagnin on 19/10/15.
//  Copyright © 2015 DIMENSION S.r.l. All rights reserved.
//

import Foundation

public let D = EventManager.sharedInstance

@objc public enum Serialization : Int {
    case None
    case UserDefaults
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
    public var swizzles = Set<Swizzle>()
    
    public var limit = 10
    public var timeInterval = 1.0 {
        didSet {
            if timeInterval < 0.25 {
                timeInterval = 0.25
            }
            self.timer?.invalidate()
            self.timer = NSTimer.scheduledTimerWithTimeInterval(timeInterval, target: self, selector: Selector("processEvents"), userInfo: nil, repeats: true)
        }
    }
    var timer : NSTimer?
    var eventsQueue = Set<Event>()
    var type = Serialization.None
    
    /**
    A shared instance of `EventManager`.
    */
    static public let sharedInstance = EventManager()

    // Only Desman can set the property or change its objects, but doing so we can make it observable to KVO
    dynamic private(set) public var events = Set<Event>()
    dynamic internal(set) public var sentEvents = Set<Event>()
    
    public func takeOff(baseURL: NSURL, appKey: String, serialization: Serialization) {
        self.type = serialization
        self.upload = true
        NetworkManager.sharedInstance.takeOff(baseURL, appKey: appKey)
        if type == .UserDefaults {
            deserializeEvents()
        }
        scheduleProcessTimer()
        // TODO: support other databases
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
        if self.type == .UserDefaults {
            self.serializeEvents()
        }
        // TODO: remove every online log linked to this device and user
    }
    
    func scheduleProcessTimer() {
        if let timer = timer {
            timer.invalidate()
        }
        self.timer = NSTimer.scheduledTimerWithTimeInterval(timeInterval, target: self, selector: Selector("processEvents"), userInfo: nil, repeats: true)
    }
    
    public func takeOff(serialization: Serialization) {
        self.type = serialization
        if type == .UserDefaults {
            deserializeEvents()
        }
        scheduleProcessTimer()
        // TODO: support other databases
    }
    
    // If you connect a KVO controller the updates can be too fast to manage
    
    public func log(event: Event){
        if shouldLog {
            self.eventsQueue.insert(event)
            if consoleLog {
                print(event.description)
            }
        }
    }
    
    public func logType(type: Type){
        if shouldLog {
            let event = Event(type)
            self.eventsQueue.insert(event)
            if consoleLog {
                print(event.description)
            }
        }
    }
    
    public func log(type: Type, payload: [String : Coding]){
        if shouldLog {
            let event = Event(type: type, payload: payload)
            self.eventsQueue.insert(event)
            if consoleLog {
                print(event.description)
            }
        }
    }
    
    func processEvents() {
        guard eventsQueue.count > 0 else  {
            // We only need to upload events already avaiable but not sent.
            NetworkManager.sharedInstance.sendEvents(self.events)
            return
        }
        
        let eventsUnion = self.events.union(eventsQueue)
        var sortedEvents = eventsUnion.sort{ $0.timestamp.compare($1.timestamp) == NSComparisonResult.OrderedDescending }
        
        if sortedEvents.count > self.limit {
            sortedEvents.removeRange(self.limit..<sortedEvents.count)
        }
        
        eventsQueue.removeAll()
        self.events = Set<Event>(sortedEvents)
        
        if self.upload {
            self.sentEvents.removeAll()
            NetworkManager.sharedInstance.sendEvents(self.events)
        }
        
        if self.type == .UserDefaults {
            self.serializeEvents()
        }
    }
    
    func serializeEvents() {
        let sortedEvents = events.sort{ $0.timestamp.compare($1.timestamp) == NSComparisonResult.OrderedDescending }
        guard sortedEvents.count > 0 else  {
            return
        }
        let eventsData = NSKeyedArchiver.archivedDataWithRootObject(sortedEvents)
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.setObject(eventsData, forKey: "events")
        defaults.synchronize()
    }
    
    public func resetEvents() {
        self.events.removeAll()
    }
    
    func deserializeEvents() {
        let defaults = NSUserDefaults.standardUserDefaults()
        if let eventsData = defaults.objectForKey("events") as? NSData {
            if let events = NSKeyedUnarchiver.unarchiveObjectWithData(eventsData) as? [Event] {
                self.eventsQueue.unionInPlace(events)
            }
        }
    }
    
    public func uploadEvents() {
        NetworkManager.sharedInstance.sendEvents(events)
    }
}