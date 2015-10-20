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
    public var limit = 100
    public var syncInterval = 5.0
    var timer : NSTimer?
    var eventsQueue = Set<Event>()
    
    var type = EventDatabase.None
    /**
    A shared instance of `EventManager`.
    */
    static public let sharedInstance = EventManager()

    // Only Desman can set the property or change its objects, but doing so we can make it observable to KVO
    dynamic private(set) public var events = Set<Event>()
    dynamic private(set) public var addedEvents = [Event]()
    dynamic private(set) public var removedEvents = [Event]()
    
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
        self.timer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: Selector("processEvents"), userInfo: nil, repeats: true)
    }
    
    public func takeOff(type: EventDatabase) {
        self.type = type
        if type == .UserDefaults {
            deserializeEvents()
        }
        scheduleProcessTimer()
        // TODO: support other databases
    }
    
    // TODO: we should rate limit the events that can be processed at the same time
    // If you connect a KVO controller the updates can be too fast to manage
    
    public func logEvent(event: Event){
        self.eventsQueue.insert(event)
    }
    
    func processEvents() {
        guard eventsQueue.count > 0 else  {
            return
        }
        for event in eventsQueue {
            self.events.insert(event)
        }
        self.addedEvents = Array(eventsQueue)
        if self.events.count > self.limit {
            var range = self.events.count - self.limit
            var temporaryEvents = [Event]()
            while range > 0 {
                let event = self.events[self.events.startIndex]
                temporaryEvents.append(event)
                self.events.removeFirst()
                range--
            }
            self.removedEvents =  temporaryEvents
        }
        if self.upload {
            NetworkManager.sharedInstance.sendEvents(eventsQueue)
        }
        if self.type == .UserDefaults {
            self.serializeEvents()
        }
        eventsQueue.removeAll()
    }
    
    func serializeEvents() {
        if (lastSync == nil) || abs(lastSync!.timeIntervalSinceNow) > syncInterval {
            lastSync = NSDate()
            print("Desman: serializing")
            // TODO: maybe we can keep only the latest events
            let sortedEvents = events.sort{ $0.timestamp.compare($1.timestamp) == NSComparisonResult.OrderedAscending }
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
            if let events = NSKeyedUnarchiver.unarchiveObjectWithData(eventsData) as? Set<Event> {
                removedEvents = Array(self.events)
                self.events = events
                addedEvents = Array(events)
            }
        }
    }
    
    public func uploadEvents() {
        NetworkManager.sharedInstance.sendEvents(events)
    }
}