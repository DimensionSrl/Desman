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
            Des.takeOff(appKey: "HIre5w9XvBFEYt3yIizCN01CeManBsEx37lKQbiQ7BE=")
            
            Des.swizzles = [.ViewWillAppear, .ViewWillDisappear]
            Des.startLogging()
            Des.consoleLog = false
            Des.limit = 40
            Des.timeInterval = 1.0
    
            // D is an alias for EventManager.sharedInstance
            Des.logType(Application.DidFinishLaunching)
            Des.log(DeviceInfo())
            Des.log(DeviceUserInfo())
            let event = Event(Type(subtype: "user"), value: "m@macteo.it")
            Des.log(event)
            Des.listenToAppLifecycleActivity()
            Des.listenToScreenshots()
        }        
    }
}

