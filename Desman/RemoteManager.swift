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
        } else {
            print("Desman: you need to select an app first")
        }
    }
}