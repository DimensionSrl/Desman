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
        // EventManager.sharedInstance.takeOff(NSURL(string: "http://example.com")!, appKey: "", serialization: .UserDefaults)
        EventManager.sharedInstance.takeOff(NSURL(string: "http://desman.dimension.it")!, appKey: "", serialization: .UserDefaults)
        // EventManager.sharedInstance.takeOff(.UserDefaults)
        EventManager.sharedInstance.swizzles = [.ViewWillAppear, .ViewWillDisappear]
        EventManager.sharedInstance.consoleLog = false
        EventManager.sharedInstance.limit = 40
        EventManager.sharedInstance.timeInterval = 1.0
        EventManager.sharedInstance.startLogging()
        // D is an alias for EventManager.sharedInstance
        D.logType(Application.DidFinishLaunching)
        D.log(DeviceInfo())
        D.log(DeviceUserInfo())
        NotificationCenterManager.sharedInstance.listenToAppLifecicleActivity()
        NotificationCenterManager.sharedInstance.listenToScreenshots()
    }
}

