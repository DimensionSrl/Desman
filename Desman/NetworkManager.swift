//
//  NetworkManager.swift
//  Desman iOS Sample
//
//  Created by Matteo Gavagnin on 19/10/15.
//  Copyright © 2015 DIMENSION S.r.l. All rights reserved.
//

import Foundation

public class NetworkManager {
    /**
    A shared instance of `NetworkManager`.
    */
    static public let sharedInstance = NetworkManager()
    
    var baseURL: NSURL?
    var session: NSURLSession?
    
    /**
    Configures `NetworkManager` with the specified base URL and app key used to authenticate with the remote service.
    
    - parameter baseURL: The base URL to be used to construct requests;
    - parameter appKey: The Authorization token that will be used authenticate the application with the remote serive.
    */
    func takeOff(baseURL: NSURL, appKey: String) {
        self.baseURL = baseURL
        let sessionConfiguration = NSURLSessionConfiguration.defaultSessionConfiguration()
        sessionConfiguration.HTTPAdditionalHeaders = ["Authorization": "Token \(appKey)"]
        self.session = NSURLSession(configuration: sessionConfiguration)
    }
    
    func sendEvent(event: Event) {
        guard (self.session != nil) else { return }
        guard event.sent == false else {
            print("Desman: event already sent, won't upload it again")
            return
        }
        guard let data = event.data else {
            print("Desman: event cannot be converted to json, cannot send it")
            return
        }
        let url = NSURL(string: "/events", relativeToURL: baseURL)!
        let request = forgeRequest(url: url, contentTypes: ["application/json"])
        request.HTTPMethod = "POST"
        request.HTTPBody = data
        let task = self.session!.dataTaskWithRequest(request, completionHandler: { (data, response, error) -> Void in
            if let error = error {
                print("Desman: cannot send event - \(error)")
            } else {
                // We should receive an identifier from the server to confirm save operation, we are going to overwrite the local one
                if let data = data {
                    do {
                        let eventDictionary = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions(rawValue: 0))
                        if let id = eventDictionary["id"] as? String {
                            event.id = id
                        } else if let id = eventDictionary["id"] as? Int {
                            event.id = "\(id)"
                        }
                    } catch let parseError as NSError {
                        print("Desman: cannot parse event response \(parseError.description)")
                    }
                }
                
                event.sent = true
                // TODO: mark it as saved if it needs to be serialized
            }
        })
        task.resume()
    }
    
    func sendEvents(events: Set<Event>) {
        // TODO: upload multiple events at the same time
        let pendingEvents = events.filter{ $0.sent == false }
        for event in pendingEvents {
            sendEvent(event)
        }
    }
    
    
    func forgeRequest(url url: NSURL, contentTypes: [String]) -> NSMutableURLRequest {
        // TODO: use cache in production
        // UseProtocolCachePolicy
        let request = NSMutableURLRequest(URL: url, cachePolicy: .ReloadIgnoringLocalCacheData, timeoutInterval: 10)
        for type in contentTypes {
            request.addValue(type, forHTTPHeaderField: "Content-Type")
            request.addValue(type, forHTTPHeaderField: "Accept")
        }
        return request
    }
}