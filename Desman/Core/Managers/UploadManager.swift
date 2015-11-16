//
//  UploadManager.swift
//  Desman
//
//  Created by Matteo Gavagnin on 19/10/15.
//  Copyright © 2015 DIMENSION S.r.l. All rights reserved.
//

import Foundation

public class UploadManager {
    /**
    A shared instance of `UploadManager`.
    */
    static public let sharedInstance = UploadManager()
    
    public var baseURL: NSURL?
    public var session: NSURLSession?
    
    var uploading = false
    
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
    
    func sendEventWithAttachment(event: Event) {
        // TODO: use a separate queue
        guard (self.session != nil) else { return }
        guard event.sent == false else {
            print("Desman: event already sent, won't upload it again")
            return
        }
        guard event.uploading == false else {
            return
        }
        event.uploading = true
        guard let attachment = event.attachment else { return }
        let url = NSURL(string: "/events.json", relativeToURL: baseURL)!
        let request = forgeRequest(url: url, contentTypes: [])
        let boundary = "Boundary-\(NSUUID().UUIDString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.HTTPMethod = "POST"
        
        request.HTTPBody = createBodyWithParameters(event.dictionary, filePathKey: "attachment", attachment: attachment, boundary: boundary)
        
        let task = self.session!.dataTaskWithRequest(request, completionHandler: { (data, response, error) -> Void in
            if let error = error {
                event.uploading = false
                print("Desman: cannot send event - \(error)")
            } else {
                // We should receive an identifier from the server to confirm save operation, we are going to overwrite the local one
                if let data = data {
                    do {
                        let eventDictionary = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions(rawValue: 0))
                        if let id = eventDictionary["id"] as? String {
                            event.id = id
                            event.sent = true
                            event.uploading = false
                            dispatch_async(dispatch_get_main_queue()) {
                                EventManager.sharedInstance.sentEvents.insert(event)
                            }
                        } else if let id = eventDictionary["id"] as? Int {
                            event.id = "\(id)"
                            event.sent = true
                            event.uploading = false
                            dispatch_async(dispatch_get_main_queue()) {
                                EventManager.sharedInstance.sentEvents.insert(event)
                            }
                        }
                    } catch let parseError as NSError {
                        event.uploading = false
                        // TODO: Should mark the event as sent, but with failure
                        print("Desman: cannot parse event response \(parseError.description) - \(String(data: data, encoding: NSUTF8StringEncoding))")
                    }
                } else {
                    event.uploading = false
                }
            }
            dispatch_async(dispatch_get_main_queue()) {
                EventManager.sharedInstance.serializeEvents()
            }
        })
        task.resume()
    }
    
    func createBodyWithParameters(parameters: [String : Coding]?, filePathKey: String?, attachment: NSData, boundary: String) -> NSData {
        let body = NSMutableData();
        if parameters != nil {
            for (key, value) in parameters! {
                if key != "payload" {
                    body.appendString("--\(boundary)\r\n")
                    body.appendString("Content-Disposition: form-data; name=\"event[\(key)]\"\r\n\r\n")
                    body.appendString("\(value)\r\n")
                } else {
                    do {
                        let payloadJson = try NSJSONSerialization.dataWithJSONObject(value, options: NSJSONWritingOptions(rawValue: 0))
                        if let stringPayload = String(data: payloadJson, encoding: NSUTF8StringEncoding) {
                            body.appendString("--\(boundary)\r\n")
                            body.appendString("Content-Disposition: form-data; name=\"event[\(key)]\"\r\n\r\n")
                            body.appendString("\(stringPayload)\r\n")
                        }
                    } catch _ {
                        
                    }
                }
            }
        }
        let filename = "attachment"
        let mimetype = "image/png"
        body.appendString("--\(boundary)\r\n")
        body.appendString("Content-Disposition: form-data; name=\"event[\(filePathKey!)]\"; filename=\"\(filename)\"\r\n")
        body.appendString("Content-Type: \(mimetype)\r\n\r\n")
        body.appendData(attachment)
        body.appendString("\r\n")
        body.appendString("--\(boundary)--\r\n")
        
        return body
    }
    
    func sendEvent(event: Event) {
        guard !uploading else { return }
        guard event.attachment == nil else {
            self.sendEventWithAttachment(event)
            return
        }
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
            self.uploading = false
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
                        // TODO: Should mark the event as sent, but with failure
                        print("Desman: cannot parse event response \(parseError.description) - \(String(data: data, encoding: NSUTF8StringEncoding))")
                    }
                }
                
                event.sent = true
                dispatch_async(dispatch_get_main_queue()) {
                    EventManager.sharedInstance.sentEvents.insert(event)
                }
            }
            dispatch_async(dispatch_get_main_queue()) {
                EventManager.sharedInstance.serializeEvents()
            }
        })
        task.resume()
        uploading = true
    }
    
    func sendEvents(events: Set<Event>) {
        guard !uploading else { return }
        guard (self.session != nil) else { return }
        var pendingEvents = events.filter{ $0.sent == false }
        let eventsWithAttachments = pendingEvents.filter{ $0.attachment != nil }
        for event in eventsWithAttachments {
            sendEventWithAttachment(event)
        }
        pendingEvents = pendingEvents.filter{ $0.attachment == nil }
        
        guard pendingEvents.count > 0 else {
            return
        }
        let url = NSURL(string: "/batch", relativeToURL: baseURL)!
        let request = forgeRequest(url: url, contentTypes: ["application/json"])
        request.HTTPMethod = "POST"
        
        let operations = pendingEvents.map{forgeSendEventOperation($0)}
        let dictionary = ["ops": operations, "sequential": true]
        
        do {
            let data = try NSJSONSerialization.dataWithJSONObject(dictionary, options: .PrettyPrinted)
            request.HTTPBody = data
            let task = self.session!.dataTaskWithRequest(request, completionHandler: { (data, response, error) -> Void in
                self.uploading = false
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
                                                    dispatch_async(dispatch_get_main_queue()) {
                                                        EventManager.sharedInstance.sentEvents.insert(event)
                                                    }
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
    
    func forgeSendEventOperation(event: Event) -> [String : AnyObject] {
        let operation : [String : AnyObject] = ["method": "post", "url": "/events", "params": event.dictionary]
        return operation
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

extension NSMutableData {
    func appendString(string: String) {
        let data = string.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)
        appendData(data!)
    }
}