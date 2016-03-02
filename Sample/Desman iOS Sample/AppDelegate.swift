//
//  AppDelegate.swift
//  Desman iOS Sample
//
//  Created by Matteo Gavagnin on 19/10/15.
//  Copyright © 2015 DIMENSION S.r.l. All rights reserved.
//

import UIKit
import Desman

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        logEvents()
        return true
    }
        
    func logEvents() {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            EventManager.sharedInstance.takeOff(NSURL(string: "http://localhost:3000")!, appKey: "aa", serialization: .CoreData)
            // EventManager.sharedInstance.takeOff(.CoreData)
            EventManager.sharedInstance.swizzles = [.ViewWillAppear, .ViewWillDisappear]
            EventManager.sharedInstance.startLogging()
            EventManager.sharedInstance.consoleLog = true
            EventManager.sharedInstance.limit = 40
            EventManager.sharedInstance.timeInterval = 1.0
    
            // D is an alias for EventManager.sharedInstance
            D.logType(Application.DidFinishLaunching)
            D.log(DeviceInfo())
            D.log(DeviceUserInfo())
            let event = Event(Type(subtype: "user"), value: "m@macteo.it")
            D.log(event)
            NotificationCenterManager.sharedInstance.listenToAppLifecycleActivity()
            NotificationCenterManager.sharedInstance.listenToScreenshots()
        }        
    }
}

