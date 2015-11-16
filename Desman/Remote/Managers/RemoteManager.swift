//
//  RemoteManager.swift
//  Desman
//
//  Created by Matteo Gavagnin on 31/10/15.
//  Copyright © 2015 DIMENSION S.r.l. All rights reserved.
//

import Foundation
#if !DESMAN_AS_COCOAPOD
import Desman
#endif

import SwiftWebSocket

public class RemoteManager : NSObject {
    var lastSync : NSDate?
    var app : App?
    var user : User? {
        didSet {
            ws.close()
            connectionId = nil
            channelToken = nil
        }
    }
    let ws = WebSocket("ws://desman.dimension.it/websocket")
    
    var connectionId : String?
    var channelToken : String?
    
    // TODO: need to implement a method to unsubscribe from a channel
    
    /**
     A shared instance of `RemoteManager`.
     */
    static public let sharedInstance = RemoteManager()
    
    // Only Desman can set the property or change its objects, but doing so we can make it observable to KVO
    dynamic internal(set) public var apps = Set<App>()
    dynamic internal(set) public var users = Set<User>()
    dynamic internal(set) public var events = Set<Event>()
    
    public func fetchApps() {
        guard (UploadManager.sharedInstance.session != nil) else { return }
        let url = NSURL(string: "/apps", relativeToURL: UploadManager.sharedInstance.baseURL)!
        let request = UploadManager.sharedInstance.forgeRequest(url: url, contentTypes: ["application/json"])
        request.HTTPMethod = "GET"
        let task = UploadManager.sharedInstance.session!.dataTaskWithRequest(request, completionHandler: { (data, response, error) -> Void in
            if let error = error {
                print("Desman: cannot get apps - \(error)")
            } else {
                if let data = data {
                    do {
                        if let appsArray = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions(rawValue: 0)) as? [[String : Coding]] {
                            var apps = Set<App>()
                            for appDictionary in appsArray {
                                if let app = App(dictionary: appDictionary) {
                                    apps.insert(app)
                                }
                            }
                            dispatch_async(dispatch_get_main_queue()) {
                                RemoteManager.sharedInstance.apps = apps
                            }
                        } else {
                            print("Desman: cannot parse apps array")
                        }
                    } catch let parseError as NSError {
                        print("Desman: cannot parse apps response \(parseError.description)")
                    }
                }
            }
        })
        task.resume()
    }
    
    public func fetchUsers(app: App) {
        guard (UploadManager.sharedInstance.session != nil) else { return }
        self.app = app
        users.removeAll()
        let url = NSURL(string: "/apps/\(app.bundle)/users", relativeToURL: UploadManager.sharedInstance.baseURL)!
        let request = UploadManager.sharedInstance.forgeRequest(url: url, contentTypes: ["application/json"])
        request.HTTPMethod = "GET"
        let task = UploadManager.sharedInstance.session!.dataTaskWithRequest(request, completionHandler: { (data, response, error) -> Void in
            if let error = error {
                print("Desman: cannot get users for \(app) - \(error)")
            } else {
                if let data = data {
                    do {
                        if let usersArray = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions(rawValue: 0)) as? [[String : Coding]] {
                            var users = Set<User>()
                            for userDictionary in usersArray {
                                if let user = User(dictionary: userDictionary) {
                                    users.insert(user)
                                }
                            }
                            dispatch_async(dispatch_get_main_queue()) {
                                self.users = users
                            }
                        } else {
                            print("Desman: cannot parse users array")
                        }
                    } catch let parseError as NSError {
                        print("Desman: cannot parse users response \(parseError.description)")
                    }
                }
            }
        })
        task.resume()
    }
    
    public func fetchEvents(app: App, user: User) {
        guard (UploadManager.sharedInstance.session != nil) else { return }
        events.removeAll()
        self.user = user
        let escapedUserUUID = user.uuid.stringByAddingPercentEncodingWithAllowedCharacters(.URLHostAllowedCharacterSet())!
        let urlString = "/apps/\(app.bundle)/users/\(escapedUserUUID)/events"
        if let url = NSURL(string: urlString, relativeToURL: UploadManager.sharedInstance.baseURL) {
            let request = UploadManager.sharedInstance.forgeRequest(url: url, contentTypes: ["application/json"])
            request.HTTPMethod = "GET"
            let task = UploadManager.sharedInstance.session!.dataTaskWithRequest(request, completionHandler: { (data, response, error) -> Void in
                if let error = error {
                    print("Desman: cannot get events for \(user) of \(app) - \(error)")
                } else {
                    if let data = data {
                        do {
                            if let eventsArray = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions(rawValue: 0)) as? [[String : Coding]] {
                                var events = Set<Event>()
                                for eventDictionary in eventsArray {
                                    if let event = Event(dictionary: eventDictionary) {
                                        events.insert(event)
                                    }
                                }
                                dispatch_async(dispatch_get_main_queue()) {
                                    RemoteManager.sharedInstance.events = events
                                }
                            } else {
                                print("Desman: cannot parse events array")
                            }
                        } catch let parseError as NSError {
                            print("Desman: cannot parse events response \(parseError.description)")
                        }
                    }
                }
            })
            task.resume()
        } else {
            print("Desman: cannot create users url \(urlString)")
        }
        subscribeSocket()
    }
    
    public func stopFetchingEvents() {
        self.ws.close()
    }

    func subscribeSocket() {

        self.ws.open()
        let pong : ()->() = {
            let emptyDictionary = [String: AnyObject]()
            if let id = self.connectionId {
                let msg : [AnyObject] = ["websocket_rails.pong", emptyDictionary, id]
                do {
                    let data = try NSJSONSerialization.dataWithJSONObject(msg, options: .PrettyPrinted)
                    if let json = String(data: data, encoding: NSUTF8StringEncoding) {
                        // print("pong")
                        self.ws.send(json)
                    }
                } catch _ {
                    
                }
            }
        }
    
        func subscribe(string: String) {
            var channel = "\(self.app!.bundle)-\(self.user!.uuid)".stringByReplacingOccurrencesOfString(" ", withString: "+")
            channel = channel.stringByAddingPercentEncodingWithAllowedCharacters(.URLQueryAllowedCharacterSet())!
            channel = channel.stringByReplacingOccurrencesOfString("'", withString: "%27")

            // print("channel \(channel)")
            let msg = ["websocket_rails.subscribe", ["data": ["channel": channel]], string]
            do {
                let data = try NSJSONSerialization.dataWithJSONObject(msg, options: .PrettyPrinted)
                if let json = String(data: data, encoding: NSUTF8StringEncoding) {
                    ws.send(json)
                    // print("subscribe")
                }
            } catch _ {
                
            }
        }
        
        ws.event.open = {
            // print("opened")
            // send()
        }
        ws.event.close = { code, reason, clean in
            print("close")
            self.channelToken = nil
            self.connectionId = nil
        }
        ws.event.error = { error in
            print("error \(error)")
        }
        ws.event.message = { message in
            if let text = message as? String {
                // print("recv: \(text)")
                
                do {
                    if let jsonParent = try NSJSONSerialization.JSONObjectWithData(text.dataUsingEncoding(NSUTF8StringEncoding)!, options: .AllowFragments) as? [AnyObject] {
                        if let json = jsonParent.first as? [AnyObject] {
                            if let name = json.first as? String {
                                if let content = json[1] as? [String: AnyObject] {
                                    if let data = content["data"] as? [String: AnyObject], id = data["connection_id"] as? String {
                                        self.connectionId = id
                                    }
                                }
                                if name == "client_connected", let id = self.connectionId {
                                    subscribe(id)
                                } else if name == "new_event" {
                                    if let content = json[1] as? [String: AnyObject] {
                                        if let data = content["data"] as? [String: Coding] {
                                            if let event = Event(dictionary: data) {
                                                self.events.insert(event)
                                                // print(event)
                                            }
                                        }
                                    }
                                } else if name == "websocket_rails.channel_token" {
                                    if let content = json[1] as? [String: AnyObject] {
                                        if let data = content["data"] as? [String: Coding] {
                                            if let token = data["token"] as? String {
                                                self.channelToken = token
                                                // print("channel token: \(token)")
                                            }
                                        }
                                    }
                                } else if name == "websocket_rails.subscribe" {
                                    // TODO: check for error
                                } else if name == "websocket_rails.ping" {
                                    pong()
                                }
                            }
                        }
                    }
                } catch _ {
                    
                }
            }
        }
    }
}