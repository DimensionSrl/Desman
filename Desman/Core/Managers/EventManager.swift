//
//  EventManager.swift
//  Desman iOS Sample
//
//  Created by Matteo Gavagnin on 19/10/15.
//  Copyright © 2015 DIMENSION S.r.l. All rights reserved.
//

import Foundation
import CoreData

public let Des = EventManager.shared

@objc public enum Serialization : Int {
    case none
    case userDefaults
    case coreData
}

@objc public enum Endpoint : Int {
    case desman
    case flow
}

@objc public enum Swizzle : Int {
    case viewWillAppear
    case viewDidAppear
    case viewWillDisappear
}

open class EventManager : NSObject {
    var lastSync : Date?
    var upload = false
    var shouldLog = false
    open var consoleLog = false
    open var swizzles = [Swizzle]()
    fileprivate var currentSession = UUID().uuidString
    
    open var limit = 100
    open var timeInterval = 1.0 {
        didSet {
            if timeInterval < 0.25 {
                timeInterval = 0.25
            }
            DispatchQueue.main.async {
                self.timer?.invalidate()
                self.timer = Timer.scheduledTimer(timeInterval: self.timeInterval, target: self, selector: #selector(EventManager.processEvents), userInfo: nil, repeats: true)
            }
        }
    }
    var timer : Timer?
    var eventsQueue = [Event]()
    var type = Serialization.none
    var endpoint = Endpoint.desman
    
    fileprivate var _flowFormatter : DateFormatter?
    
    var flowDateFormatter : DateFormatter {
        if (_flowFormatter == nil) {
            createFlowFormatter()
        }
        
        return _flowFormatter!
    }
    
    fileprivate func createFlowFormatter() {
        let flowFormatter = DateFormatter()
        flowFormatter.locale = NSLocale(localeIdentifier: "it_IT") as Locale!
        flowFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        flowFormatter.timeZone = TimeZone.current
        _flowFormatter = flowFormatter
    }
    
    open func resetSession() -> String {
        currentSession = UUID().uuidString
        return currentSession
    }
    
    var session : String {
        return currentSession
    }
    
    open func listenToAppLifecycleActivity() {
        NotificationCenterManager.sharedInstance.listenToAppLifecycleActivity()
    }
    
    open func listenToScreenshots() {
        NotificationCenterManager.sharedInstance.listenToScreenshots()
    }

    open func stopListeningToAppLifecycleActivity() {
        NotificationCenterManager.sharedInstance.stopListeningToAppLifecycleActivity()
    }
    
    open func stopListeningToScreenshots() {
        NotificationCenterManager.sharedInstance.stopListeningToScreenshots()
    }

    
    /**
    A shared instance of `EventManager`.
    */
    static open let shared = EventManager()

    // Only Desman can set the property or change its objects, but doing so we can make it observable to KVO
    dynamic fileprivate(set) open var events = [Event]()
    dynamic internal(set) open var sentEvents = [Event]()
    
    open func takeOff(_ baseURL: URL, appKey: String, serialization: Serialization) {
        self.type = serialization
        self.upload = true
        UploadManager.sharedInstance.takeOff(baseURL, appKey: appKey)
        deserializeEvents()
        
        scheduleProcessTimer()
        
        // We immediately upload app icon and its name
        // TODO: optimize querying the remote server if the app exists, if it doesn't, upload name and icon
        self.forceLog(AppInfo())
    }
    
    open func takeOff(_ baseURL: URL, appKey: String, serialization: Serialization, endpoint: Endpoint) {
        self.type = serialization
        self.upload = true
        
        self.endpoint = endpoint
        
        if endpoint == .desman {
            UploadManager.sharedInstance.takeOff(baseURL, appKey: appKey)
        } else if endpoint == .flow {
            FlowManager.sharedInstance.takeOff(appKey)
        }
        
        deserializeEvents()
        
        scheduleProcessTimer()
        
        // We immediately upload app icon and its name
        // TODO: optimize querying the remote server if the app exists, if it doesn't, upload name and icon
        self.forceLog(AppInfo())
    }
    
    open func takeOff(appKey: String) {
        let baseURL = URL(string: "https://desman.dimension.it")!
        let serialization : Serialization = .coreData
        takeOff(baseURL, appKey: appKey, serialization: serialization)
    }
    
    open func takeOff(appKey: String, endpoint: Endpoint) {
        let baseURL = URL(string: "https://desman.dimension.it")!
        let serialization : Serialization = .coreData
        self.endpoint = endpoint
        if endpoint == .desman {
            UploadManager.sharedInstance.takeOff(baseURL, appKey: appKey)
        } else if endpoint == .flow {
            FlowManager.sharedInstance.takeOff(appKey)
        }
        takeOff(baseURL, appKey: appKey, serialization: serialization)
    }
    
    open func startLogging() {
        shouldLog = true
        
        if endpoint == .desman {
            self.logType(AppCycle.LogEnable)
        } else if endpoint == .flow {
            self.log(FlowApp())
            self.log(FlowDeviceName())
            self.log(FlowDeviceType())
            self.log(FlowDeviceID())
        }
    }
    
    open func stopLogging() {
        if endpoint == .desman {
            self.logType(AppCycle.LogDisable)
        }
        
        self.processEvents()
        shouldLog = false
    }
    
    open func purgeLogs() {
        self.events.removeAll()
        self.serializeEvents()
        // TODO: remove every online log linked to this device and user
    }
    
    func scheduleProcessTimer() {
        DispatchQueue.main.async {
            if let timer = self.timer {
                timer.invalidate()
            }
            self.timer = Timer.scheduledTimer(timeInterval: self.timeInterval, target: self, selector: #selector(EventManager.processEvents), userInfo: nil, repeats: true)
        }
    }
    
    open func takeOff(_ serialization: Serialization) {
        self.type = serialization
        deserializeEvents()
        scheduleProcessTimer()
        // TODO: support other databases
    }
    
    open func log(_ event: Event){
        if shouldLog {
            self.eventsQueue.append(event)
            if type == .coreData {
                event.saveCDEvent()
            }
            if consoleLog {
                print("Event: \(event.description)")
            }
        }
    }
    
    func forceLog(_ event: Event){
        self.eventsQueue.append(event)
        if type == .coreData {
            event.saveCDEvent()
        }
        if consoleLog {
            print("Event: \(event.description)")
        }
    }
    
    open func logType(_ type: DType){
        if shouldLog {
            let event = Event(type)
            self.eventsQueue.append(event)
            if self.type == .coreData {
                event.saveCDEvent()
            }
            if consoleLog {
                print("Event: \(event.description)")
            }
        }
    }
    
    open func log(_ type: DType, payload: [String : Any]){
        if shouldLog {
            let event = Event(type: type, payload: payload)
            self.eventsQueue.append(event)
            if self.type == .coreData {
                event.saveCDEvent()
            }
            if consoleLog {
                print("Event: \(event.description)")
            }
        }
    }

    open func log(_ type: DType, value: String, desc: String){
        if shouldLog {
            let event = Event(type, value: value, desc: desc)
            self.eventsQueue.append(event)
            if self.type == .coreData {
                event.saveCDEvent()
            }
            if consoleLog {
                print("Event: \(event.description)")
            }
        }
    }
    
    open func log(_ type: DType, desc: String){
        if shouldLog {
            let event = Event(type, desc: desc)
            self.eventsQueue.append(event)
            if self.type == .coreData {
                event.saveCDEvent()
            }
            if consoleLog {
                print("Event: \(event.description)")
            }
        }
    }
    
    open func log(_ type: DType, desc: String, payload: [String : Any]){
        if shouldLog {
            let event = Event(type, desc: desc)
            event.payload = payload
            self.eventsQueue.append(event)
            if self.type == .coreData {
                event.saveCDEvent()
            }
            if consoleLog {
                print("Event: \(event.description)")
            }
        }
    }

    
    func processEvents() {
        guard eventsQueue.count > 0 else  {
            // We only need to upload events already avaiable but not sent.
            if endpoint == .desman {
                UploadManager.sharedInstance.sendEvents(self.events)
            } else if endpoint == .flow {
                FlowManager.sharedInstance.sendEvents(self.events)
            }
            
            return
        }
        
        self.events.append(contentsOf: eventsQueue)
        
        var sortedEvents = self.events.sorted{ $0.timestamp.compare($1.timestamp as Date) == ComparisonResult.orderedDescending }
        
        if sortedEvents.count > self.limit {
            sortedEvents.removeSubrange(self.limit..<sortedEvents.count)
        }
        
        eventsQueue.removeAll()
        self.events = sortedEvents
        
        if self.upload {
            self.sentEvents.removeAll()
            if endpoint == .desman {
                UploadManager.sharedInstance.sendEvents(self.events)
            } else if endpoint == .flow {
                FlowManager.sharedInstance.sendEvents(self.events)
            }
        }
        
        self.serializeEvents()
    }
    
    func serializeEvents() {
        guard events.count > 0 else { return }
        if type == .userDefaults {
            let sortedEvents = events.sorted{ $0.timestamp.compare($1.timestamp as Date) == ComparisonResult.orderedDescending }
            let eventsData = NSKeyedArchiver.archivedData(withRootObject: sortedEvents)
            let defaults = UserDefaults.standard
            defaults.set(eventsData, forKey: "events")
            defaults.synchronize()
        }
    }
    
    open func resetEvents() {
        self.events.removeAll()
    }
    
    func deserializeEvents() {
        if type == .userDefaults {
            let defaults = UserDefaults.standard
            if let eventsData = defaults.object(forKey: "events") as? Data {
                if let events = NSKeyedUnarchiver.unarchiveObject(with: eventsData) as? [Event] {
                    self.eventsQueue.append(contentsOf: events)
                }
            }
        } else if type == .coreData {
            let request : NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "CDEvent")
            if let fetchedEvents = CoreDataSerializerManager.sharedInstance.executeFetchRequest(request) {
                let mappedEvents = fetchedEvents.map{Event(cdevent: $0 as! CDEvent)}
                self.eventsQueue.append(contentsOf: mappedEvents)
            }
        }
    }
    
    open func uploadEvents() {
        if endpoint == .desman {
            UploadManager.sharedInstance.sendEvents(self.events)
        } else if endpoint == .flow {
            FlowManager.sharedInstance.sendEvents(self.events)
        }
    }
}
