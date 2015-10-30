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
    
    public func listenToScreenshots() {
        startListening(UIApplicationUserDidTakeScreenshotNotification, type: Notification(subtype: "screenshot"))
    }
    
    public func stopListeningToScreenshots() {
        stopListening(UIApplicationUserDidTakeScreenshotNotification)
    }
    
    public func listenToAppLifecicleActivity() {
        startListening(UIApplicationDidBecomeActiveNotification, type: Application.DidBecomeActive)
        startListening(UIApplicationDidEnterBackgroundNotification, type: Application.DidEnterBackground)
        // startListening(UIApplicationDidFinishLaunchingNotification, type: Application.DidFinishLaunching)
        startListening(UIApplicationWillEnterForegroundNotification, type: Application.WillEnterForeground)
        startListening(UIApplicationWillResignActiveNotification, type: Application.WillResignActive)
        startListening(UIApplicationWillTerminateNotification, type: Application.WillTerminate)
    }
    
    public func stopListeningToAppLifecycleActivity() {
        stopListening(UIApplicationDidBecomeActiveNotification)
        stopListening(UIApplicationDidEnterBackgroundNotification)
        // stopListening(UIApplicationDidFinishLaunchingNotification)
        stopListening(UIApplicationWillEnterForegroundNotification)
        stopListening(UIApplicationWillResignActiveNotification)
        stopListening(UIApplicationWillTerminateNotification)
    }
    
    public func startListening(name: String, type: Type) {
        stopListening(name)
        NSNotificationCenter.defaultCenter().addObserverForName(name, object: nil, queue: nil) { (notification) -> Void in
            var payload = [String: Coding]()
            if let object = notification.object {
                if let object = object as? Coding {
                    payload["object"] = object
                } else {
                    payload["object"] = object.description
                }
            }
            if let userInfo = notification.userInfo {
                payload["userInfo"] = userInfo
            }
            if type.subtype == "" {
                type.subtype = notification.name
            }
            let event = Event(type: type, payload: payload)
            EventManager.sharedInstance.log(event)
        }
    }
    
    public func stopListening(name: String) {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: name, object: nil)
    }
}