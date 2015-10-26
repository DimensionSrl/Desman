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
                EventManager.sharedInstance.sentEvents.insert(event)
            }
        })
        task.resume()
    }
    
    func sendEvents(events: Set<Event>) {
        guard (self.session != nil) else { return }
        let pendingEvents = events.filter{ $0.sent == false }
        let url = NSURL(string: "/batch", relativeToURL: baseURL)!
        let request = forgeRequest(url: url, contentTypes: ["application/json"])
        request.HTTPMethod = "POST"
        
        let operations = pendingEvents.map{forgeSendEventOperation($0)}
        let dictionary = ["ops": operations, "sequential": true]
        
        do {
            let data = try NSJSONSerialization.dataWithJSONObject(dictionary, options: .PrettyPrinted)
            request.HTTPBody = data
            let task = self.session!.dataTaskWithRequest(request, completionHandler: { (data, response, error) -> Void in
                if let error = error {
                    print("Desman: cannot send event - \(error)")
                } else {
                    // We should receive an identifier from the server to confirm save operation, we are going to overwrite the local one
                    if let data = data {
                        do {
                            let parsedData = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions(rawValue: 0))
                            if let results = parsedData["results"] as? [[String : AnyObject]] {
                                for result in results {
                                    if let bodyJson = result["body"] as? String, body = bodyJson.dataUsingEncoding(NSUTF8StringEncoding) {
                                        do {
                                            let body = try NSJSONSerialization.JSONObjectWithData(body, options: NSJSONReadingOptions(rawValue: 0))
                                            if let id = body["id"] as? Int, let uuidString = body["uuid"] as? String, let uuid = NSUUID(UUIDString: uuidString) {
                                                let filteredEvents = events.filter{$0.uuid == uuid}
                                                if let event = filteredEvents.first {
                                                    event.id = "\(id)"
                                                    event.sent = true
                                                    EventManager.sharedInstance.sentEvents.insert(event)
                                                }
                                            }
                                        } catch let parseBodyError as NSError {
                                            print("Desman: cannot parse body event response \(parseBodyError.description)")
                                        }
                                    } else {
                                        print("Desman: cannot parse result \(result)")
                                    }
                                }
                            } else {
                                print("Desman: cannot find and parse *results* data \(parsedData)")
                            }
                        } catch let parseError as NSError {
                            print("Desman: cannot parse event response \(parseError.description)")
                        }
                    }
                }
            })
            task.resume()
        } catch let error {
            print("Desman: cannot serialize events \(error)")
        }
    }
    
    func forgeSendEventOperation(event: Event) -> [String : AnyObject] {
        let operation : [String : AnyObject] = ["method": "post", "url": "/events", "params": event.dictionary]
        return operation
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