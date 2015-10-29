//
//  NotificationCenterListener.swift
//  Desman iOS Sample
//
//  Created by Matteo Gavagnin on 19/10/15.
//  Copyright © 2015 DIMENSION S.r.l. All rights reserved.
//

import Foundation

let kNotificationCenterEvent = "notificationCenterEvent"

public class NotificationCenterListener {
    /**
    A shared instance of `NotificationCenterListener`.
    */
    static public let sharedInstance = NotificationCenterListener()
    
    public func startListening() {
        stopListening()
        NSNotificationCenter.defaultCenter().addObserverForName(nil, object: nil, queue: nil) { (notification) -> Void in
            var payload = [String: Coding]()
            if let object = notification.object {
                payload["object"] = object.description
            }
            if let userInfo = notification.userInfo {
                payload["userInfo"] = userInfo.description
            }
            let event = Event(type: Notification(subtype: notification.name), payload: payload)
            EventManager.sharedInstance.log(event)
        }
    }
    
    public func stopListening() {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
}