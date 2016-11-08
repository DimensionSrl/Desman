//
//  UploadManager.swift
//  Desman
//
//  Created by Matteo Gavagnin on 19/10/15.
//  Copyright © 2015 DIMENSION S.r.l. All rights reserved.
//

import Foundation

open class UploadManager {
    /**
    A shared instance of `UploadManager`.
    */
    static open let sharedInstance = UploadManager()
    
    open var baseURL: URL?
    open var session: URLSession?
    
    var uploading = false
    
    /**
    Configures `NetworkManager` with the specified base URL and app key used to authenticate with the remote service.
    
    - parameter baseURL: The base URL to be used to construct requests;
    - parameter appKey: The Authorization token that will be used authenticate the application with the remote serive.
    */
    func takeOff(_ baseURL: URL, appKey: String) {
        self.baseURL = baseURL
        let sessionConfiguration = URLSessionConfiguration.default
        sessionConfiguration.httpAdditionalHeaders = ["Authorization": "Token \(appKey)"]
        self.session = URLSession(configuration: sessionConfiguration)        
    }
    
    func sendEventWithAttachment(_ event: Event) {
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
        let url = URL(string: "/events.json", relativeTo: baseURL)!
        var request = forgeRequest(url: url, contentTypes: [])
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        
        request.httpBody = createBodyWithParameters(event.dictionary, filePathKey: "attachment", attachment: attachment as Data, boundary: boundary)
        
        guard let session = self.session else { return }
        
        let task = session.dataTask(with: request, completionHandler: { (data, response, error) -> Void in
            if let error = error {
                event.uploading = false
                print("Desman: cannot send event - \(error.localizedDescription)")
            } else {
                // We should receive an identifier from the server to confirm save operation, we are going to overwrite the local one
                if let data = data {
                    do {
                        let eventDictionary = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions(rawValue: 0)) as! [String: Any]
                        if let id = eventDictionary["id"] as? String {
                            event.id = id
                            event.sent = true
                            event.uploading = false
                            if EventManager.shared.type == .coreData {
                                event.saveCDEvent()
                            }
                            DispatchQueue.main.async {
                                EventManager.shared.sentEvents.append(event)
                            }
                        } else if let id = eventDictionary["id"] as? Int {
                            event.id = "\(id)"
                            event.sent = true
                            event.uploading = false
                            if EventManager.shared.type == .coreData {
                                event.saveCDEvent()
                            }
                            DispatchQueue.main.async {
                                EventManager.shared.sentEvents.append(event)
                            }
                        }
                    } catch let parseError as NSError {
                        event.uploading = false
                        // TODO: Should mark the event as sent, but with failure
                        print("Desman: cannot parse event response \(parseError.description) - \(String(data: data, encoding: String.Encoding.utf8))")
                    }
                } else {
                    event.uploading = false
                }
            }
            DispatchQueue.main.async {
                EventManager.shared.serializeEvents()
            }
        })
        task.resume()
    }
    
    func createBodyWithParameters(_ parameters: [String : Any]?, filePathKey: String?, attachment: Data, boundary: String) -> Data {
        let body = NSMutableData();
        if parameters != nil {
            for (key, value) in parameters! {
                if key != "payload" {
                    body.appendString("--\(boundary)\r\n")
                    body.appendString("Content-Disposition: form-data; name=\"event[\(key)]\"\r\n\r\n")
                    body.appendString("\(value)\r\n")
                } else {
                    do {
                        let payloadJson = try JSONSerialization.data(withJSONObject: value, options: JSONSerialization.WritingOptions(rawValue: 0))
                        if let stringPayload = String(data: payloadJson, encoding: String.Encoding.utf8) {
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
        body.append(attachment)
        body.appendString("\r\n")
        body.appendString("--\(boundary)--\r\n")
        
        return body as Data
    }
    
    func sendEvent(_ event: Event) {
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
        let url = URL(string: "/events", relativeTo: baseURL)!
        var request = forgeRequest(url: url, contentTypes: ["application/json"])
        request.httpMethod = "POST"
        request.httpBody = data as Data
        let task = self.session!.dataTask(with: request, completionHandler: { (data, response, error) -> Void in
            self.uploading = false
            if let error = error {
                print("Desman: cannot send event \(error.localizedDescription)")
            } else {
                // We should receive an identifier from the server to confirm save operation, we are going to overwrite the local one
                if let data = data {
                    do {
                        let eventDictionary = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions(rawValue: 0)) as! [String: Any]
                        if let id = eventDictionary["id"] as? String {
                            event.id = id
                        } else if let id = eventDictionary["id"] as? Int {
                            event.id = "\(id)"
                        }
                    } catch let parseError as NSError {
                        // TODO: Should mark the event as sent, but with failure
                        print("Desman: cannot parse event response \(parseError.description) - \(String(data: data, encoding: String.Encoding.utf8))")
                    }
                }
                
                event.sent = true
                if EventManager.shared.type == .coreData {
                    event.saveCDEvent()
                }
                DispatchQueue.main.async {
                    EventManager.shared.sentEvents.append(event)
                }
            }
            DispatchQueue.main.async {
                EventManager.shared.serializeEvents()
            }
        })
        task.resume()
        uploading = true
    }
    
    func sendEvents(_ events: [Event]) {
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
        let url = URL(string: "/batch", relativeTo: baseURL)!
        var request = forgeRequest(url: url, contentTypes: ["application/json"])
        request.httpMethod = "POST"
        
        let operations = pendingEvents.map{forgeSendEventOperation($0)}
        let dictionary = ["ops": operations, "sequential": true] as [String : Any]
        
        do {
            let data = try JSONSerialization.data(withJSONObject: dictionary, options: .prettyPrinted)
            request.httpBody = data
            let task = self.session!.dataTask(with: request, completionHandler: { (data, response, error) -> Void in
                self.uploading = false
                if let error = error {
                    print("Desman: cannot send event - \(error.localizedDescription)")
                } else {
                    // We should receive an identifier from the server to confirm save operation, we are going to overwrite the local one
                    if let data = data {
                        do {
                            let parsedData = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions(rawValue: 0)) as! [String: Any]
                            if let results = parsedData["results"] as? [[String : AnyObject]] {
                                for result in results {
                                    if let bodyJson = result["body"] as? String, let body = bodyJson.data(using: String.Encoding.utf8) {
                                        do {
                                            let body = try JSONSerialization.jsonObject(with: body, options: JSONSerialization.ReadingOptions(rawValue: 0)) as! [String: Any]
                                            if let id = body["id"] as? Int, let uuidString = body["uuid"] as? String, let uuid = UUID(uuidString: uuidString) {
                                                let filteredEvents = events.filter{$0.uuid == uuid}
                                                if let event = filteredEvents.first {
                                                    event.id = "\(id)"
                                                    event.sent = true
                                                    if EventManager.shared.type == .coreData {
                                                        event.saveCDEvent()
                                                    }
                                                    DispatchQueue.main.async {
                                                        EventManager.shared.sentEvents.append(event)
                                                    }
                                                }
                                            } else {
                                                print("Desman: cannot find id in body \(body)")
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
                DispatchQueue.main.async {
                    EventManager.shared.serializeEvents()
                }
            })
            task.resume()
            uploading = true
        } catch let error {
            print("Desman: cannot serialize events \(error)")
        }
    }
    
    func forgeSendEventOperation(_ event: Event) -> [String : AnyObject] {
        let operation : [String : AnyObject] = ["method": "post" as AnyObject, "url": "/events" as AnyObject, "params": event.dictionary as AnyObject]
        return operation
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

extension NSMutableData {
    func appendString(_ string: String) {
        let data = string.data(using: String.Encoding.utf8, allowLossyConversion: true)
        append(data!)
    }
}
