//
//  EventManager.swift
//  Desman iOS Sample
//
//  Created by Matteo Gavagnin on 19/10/15.
//  Copyright © 2015 DIMENSION S.r.l. All rights reserved.
//

import Foundation

public enum EventDatabase {
    case None
    case UserDefaults
}

public class EventManager : NSObject {
    var lastSync : NSDate?
    var upload = false
    public var limit = 10
    public var syncInterval = 5.0
    public var processInterval = 1.0 {
        didSet {
            if processInterval < 0.25 {
                processInterval = 0.25
            }
            self.timer?.invalidate()
            self.timer = NSTimer.scheduledTimerWithTimeInterval(processInterval, target: self, selector: Selector("processEvents"), userInfo: nil, repeats: true)
        }
    }
    var timer : NSTimer?
    var eventsQueue = Set<Event>()
    var type = EventDatabase.None
    
    /**
    A shared instance of `EventManager`.
    */
    static public let sharedInstance = EventManager()

    // Only Desman can set the property or change its objects, but doing so we can make it observable to KVO
    dynamic private(set) public var events = Set<Event>()
    dynamic internal(set) public var sentEvents = Set<Event>()
    
    public func takeOff(baseURL: NSURL, appKey: String, type: EventDatabase) {
        self.type = type
        self.upload = true
        NetworkManager.sharedInstance.takeOff(baseURL, appKey: appKey)
        if type == .UserDefaults {
            deserializeEvents()
        }
        scheduleProcessTimer()
        // TODO: support other databases
    }
    
    func scheduleProcessTimer() {
        if let timer = timer {
            timer.invalidate()
        }
        self.timer = NSTimer.scheduledTimerWithTimeInterval(processInterval, target: self, selector: Selector("processEvents"), userInfo: nil, repeats: true)
    }
    
    public func takeOff(type: EventDatabase) {
        self.type = type
        if type == .UserDefaults {
            deserializeEvents()
        }
        scheduleProcessTimer()
        // TODO: support other databases
    }
    
    // If you connect a KVO controller the updates can be too fast to manage
    
    public func logEvent(event: Event){
        self.eventsQueue.insert(event)
    }
    
    func processEvents() {
        guard eventsQueue.count > 0 else  {
            return
        }
        let eventsUnion = self.events.union(eventsQueue)
        var sortedEvents = eventsUnion.sort{ $0.timestamp.compare($1.timestamp) == NSComparisonResult.OrderedDescending }
        
        if sortedEvents.count > self.limit {
            sortedEvents.removeRange(self.limit..<sortedEvents.count)
        }
        
        if self.upload {
            self.sentEvents.removeAll()
            NetworkManager.sharedInstance.sendEvents(eventsQueue)
        }
        
        if self.type == .UserDefaults {
            self.serializeEvents()
        }
        
        eventsQueue.removeAll()
        self.events = Set<Event>(sortedEvents)
    }
    
    func serializeEvents() {
        if (lastSync == nil) || abs(lastSync!.timeIntervalSinceNow) > syncInterval {
            lastSync = NSDate()
            let sortedEvents = events.sort{ $0.timestamp.compare($1.timestamp) == NSComparisonResult.OrderedDescending }
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