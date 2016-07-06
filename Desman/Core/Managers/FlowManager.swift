//
//  FlowManager.swift
//  Desman
//
//  Created by Matteo Gavagnin on 25/05/16.
//  Copyright © 2015 DIMENSION S.r.l. All rights reserved.
//

import Foundation

public class FlowManager {
    /**
     A shared instance of `FlowManager`.
     */
    static public let sharedInstance = FlowManager()
    public var session: NSURLSession?
    
    var uploading = false
    var appKey = ""
    
    /**
     Configures the specified app key used to authenticate with the remote service.
     
     - parameter appKey: The Authorization token that will be used authenticate the application with the remote serive.
     */
    func takeOff(appKey: String) {
        self.appKey = appKey
        let sessionConfiguration = NSURLSessionConfiguration.defaultSessionConfiguration()
        sessionConfiguration.HTTPAdditionalHeaders = ["Authorization": "Token \(appKey)"]
        self.session = NSURLSession(configuration: sessionConfiguration)
    }
    
    func sendEvents(events: [Event]) {
        guard !uploading else { return }
        guard (self.session != nil) else { return }
        var pendingEvents = events.filter{ $0.sent == false }
        pendingEvents = pendingEvents.filter{ $0.attachment == nil }
        
        guard pendingEvents.count > 0 else {
            return
        }
        // TODO: expose it as configurable
        let url = NSURL(string: "http://apps.dimension.it/appflow/tracker/")!

        let request = forgeRequest(url: url, contentTypes: ["application/json"])
        request.HTTPMethod = "POST"
        
        let operations = pendingEvents.map{$0.flowDictionary}
        let dictionary = ["events": operations, "token": appKey, "session": EventManager.sharedInstance.session]
        
        do {
            let data = try NSJSONSerialization.dataWithJSONObject(dictionary, options: .PrettyPrinted)
            
            request.HTTPBody = data
            
            let task = self.session!.dataTaskWithRequest(request, completionHandler: { (data, response, error) -> Void in
                self.uploading = false
                if let error = error {
                    print("Desman: cannot send event - \(error.localizedDescription)")
                } else {
                    for event in pendingEvents {
                        event.sent = true
                        if EventManager.sharedInstance.type == .CoreData {
                            event.saveCDEvent()
                        }
                        dispatch_async(dispatch_get_main_queue()) {
                            EventManager.sharedInstance.sentEvents.append(event)
                        }
                    }
                }
                dispatch_async(dispatch_get_main_queue()) {
                    EventManager.sharedInstance.serializeEvents()
                }
            })
            task.resume()
            uploading = true
        } catch let error {
            print("Desman: cannot serialize events \(error)")
        }
    }
    
    public func forgeRequest(url url: NSURL, contentTypes: [String]) -> NSMutableURLRequest {
        // TODO: use cache in production
        // UseProtocolCachePolicy
        let request = NSMutableURLRequest(URL: url, cachePolicy: .ReloadIgnoringLocalCacheData, timeoutInterval: 30)
        for type in contentTypes {
            request.addValue(type, forHTTPHeaderField: "Content-Type")
            request.addValue(type, forHTTPHeaderField: "Accept")
        }
        return request
    }
}