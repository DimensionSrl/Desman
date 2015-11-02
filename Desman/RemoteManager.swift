//
//  RemoteManager.swift
//  Desman
//
//  Created by Matteo Gavagnin on 31/10/15.
//  Copyright © 2015 DIMENSION S.r.l. All rights reserved.
//

import Foundation

public class RemoteManager : NSObject {
    var lastSync : NSDate?
    var app : App?
    var user : User?

    var connectionId : String?
    var channelToken : String?
    
    /**
     A shared instance of `RemoteManager`.
     */
    static public let sharedInstance = RemoteManager()
    
    // Only Desman can set the property or change its objects, but doing so we can make it observable to KVO
    dynamic internal(set) public var apps = Set<App>()
    dynamic internal(set) public var users = Set<User>()
    dynamic internal(set) public var events = Set<Event>()
    
    public func fetchApps() {
        NetworkManager.sharedInstance.fetchApps()
    }
    
    public func fetchUsers(app: App) {
        self.app = app
        users.removeAll()
        NetworkManager.sharedInstance.fetchUsers(app)
    }
    
    public func fetchEvents(user: User) {
        events.removeAll()
        self.user = user
        if let app = app {
            NetworkManager.sharedInstance.fetchEvents(app, user: user)
            subscribeSocket()
        } else {
            print("Desman: you need to select an app first")
        }
    }
    
    func subscribeSocket() {
        var messageNum = 0
        let ws = WebSocket("ws://desman.dimension.it/websocket")

        let pong : ()->() = {
            let emptyDictionary = [String: AnyObject]()
            if let id = self.connectionId {
                let msg : [AnyObject] = ["websocket_rails.pong", emptyDictionary, id]
                do {
                    let data = try NSJSONSerialization.dataWithJSONObject(msg, options: .PrettyPrinted)
                    if let json = String(data: data, encoding: NSUTF8StringEncoding) {
                        // print("pong")
                        ws.send(json)
                    }
                } catch _ {
                    
                }
            }
        }
        
        func subscribe(string: String) {

            // FIXME: be sure of what I'm doing
            let channel = "\(self.app!.bundle)-\(self.user!.uuid)".stringByReplacingOccurrencesOfString(" ", withString: "+")
            
            let msg = ["websocket_rails.subscribe", ["data": ["channel": channel]], string]
            do {
                let data = try NSJSONSerialization.dataWithJSONObject(msg, options: .PrettyPrinted)
                if let json = String(data: data, encoding: NSUTF8StringEncoding) {
                    ws.send(json)
                    print(json)
                }
            } catch _ {
                
            }
        }
        
        ws.event.open = {
            print("opened")
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
                                                print("channel token: \(token)")
                                            }
                                        }
                                    }
                                } else if name == "websocket_rails.subscribe" {
                                    // TODO: check for error
                                } else if name == "websocket_rails.ping" {
                                    // TODO: probably need to reply with a pong
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