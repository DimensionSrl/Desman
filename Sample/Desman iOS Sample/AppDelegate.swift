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

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        logEvents()
        // logFlow()
        return true
    }
        
    func logEvents() {
        DispatchQueue.main.async {
            Des.takeOff(appKey: "HIre5w9XvBFEYt3yIizCN01CeManBsEx37lKQbiQ7BE=")
            Des.swizzles = [.viewWillAppear, .viewWillDisappear]
            Des.consoleLog = true
            Des.startLogging()
            Des.limit = 40
            Des.timeInterval = 1.0
    
            // Des is an alias for EventManager.shared
            Des.logType(AppCycle.DidFinishLaunching)
            Des.log(DeviceInfo())
            Des.log(DeviceUserInfo())
            let event = Event(DType(subtype: "user"), value: "m@macteo.it")
            Des.log(event)
            Des.listenToAppLifecycleActivity()
            Des.listenToScreenshots()
        }        
    }
    
    func logFlow() {
        DispatchQueue.main.async {
            Des.takeOff(appKey: "E3128D2E-9C65-44F0-9AF4-F69DD49448DC", endpoint: .flow)
            
            Des.swizzles = [.viewWillAppear, .viewWillDisappear]
            Des.startLogging()
            Des.consoleLog = false
            Des.limit = 40
            Des.timeInterval = 1.0
            
            // Des is an alias for EventManager.shared
            Des.logType(AppCycle.DidFinishLaunching)
            Des.log(DeviceInfo())
            Des.log(DeviceUserInfo())
            let event = Event(DType(subtype: "user"), value: "m@macteo.it")
            Des.log(event)
            Des.listenToAppLifecycleActivity()
            Des.listenToScreenshots()
        }
    }
}

