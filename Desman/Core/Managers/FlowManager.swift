//
//  FlowManager.swift
//  Desman
//
//  Created by Matteo Gavagnin on 25/05/16.
//  Copyright © 2015 DIMENSION S.r.l. All rights reserved.
//

import Foundation

open class FlowManager {
    /**
     A shared instance of `FlowManager`.
     */
    static open let sharedInstance = FlowManager()
    open var session: URLSession?
    
    var uploading = false
    var appKey = ""
    
    /**
     Configures the specified app key used to authenticate with the remote service.
     
     - parameter appKey: The Authorization token that will be used authenticate the application with the remote serive.
     */
    func takeOff(_ appKey: String) {
        self.appKey = appKey
        let sessionConfiguration = URLSessionConfiguration.default
        sessionConfiguration.httpAdditionalHeaders = ["Authorization": "Token \(appKey)"]
        self.session = URLSession(configuration: sessionConfiguration)
    }
    
    func sendEvents(_ events: [Event]) {
        guard !uploading else { return }
        guard (self.session != nil) else { return }
        var pendingEvents = events.filter{ $0.sent == false }
        pendingEvents = pendingEvents.filter{ $0.attachment == nil }
        
        guard pendingEvents.count > 0 else {
            return
        }
        // TODO: expose it as configurable
        let url = URL(string: "http://apps.dimension.it/appflow/tracker/v2/")!

        var request = forgeRequest(url: url, contentTypes: ["application/json"])
        request.httpMethod = "POST"
        
        let operations = pendingEvents.map{$0.flowDictionary}
        let dictionary = ["events": operations, "token": appKey, "session": EventManager.sharedInstance.session] as [String : Any]
        
        do {
            let data = try JSONSerialization.data(withJSONObject: dictionary, options: .prettyPrinted)
            
            request.httpBody = data
            
            let task = self.session!.dataTask(with: request, completionHandler: { (data, response, error) -> Void in
                self.uploading = false
                if let error = error {
                    print("Desman: cannot send event - \(error.localizedDescription)")
                } else {
                    for event in pendingEvents {
                        event.sent = true
                        if EventManager.sharedInstance.type == .coreData {
                            event.saveCDEvent()
                        }
                        DispatchQueue.main.async {
                            EventManager.sharedInstance.sentEvents.append(event)
                        }
                    }
                }
                DispatchQueue.main.async {
                    EventManager.sharedInstance.serializeEvents()
                }
            })
            task.resume()
            uploading = true
        } catch let error {
            print("Desman: cannot serialize events \(error)")
        }
    }
    
    open func forgeRequest(url: URL, contentTypes: [String]) -> URLRequest {
        // TODO: use cache in production
        // UseProtocolCachePolicy
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 30)
        for type in contentTypes {
            request.addValue(type, forHTTPHeaderField: "Content-Type")
            request.addValue(type, forHTTPHeaderField: "Accept")
        }
        return request
    }
}
