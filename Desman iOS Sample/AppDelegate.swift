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
        EventManager.sharedInstance.takeOff(NSURL(string: "http://desman.dimension.it")!, appKey: "", type: .UserDefaults)
        
        EventManager.sharedInstance.log(Application.DidFinishLaunching)
        EventManager.sharedInstance.log(SampleType.Unknown)
        EventManager.sharedInstance.limit = 40
        // NotificationCenterListener.sharedInstance.startListening()
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        EventManager.sharedInstance.log(Application.WillResignActive)
    }

    func applicationDidEnterBackground(application: UIApplication) {
        EventManager.sharedInstance.log(Application.DidEnterBackground)
    }

    func applicationWillEnterForeground(application: UIApplication) {
        EventManager.sharedInstance.log(Application.WillEnterForeground)
    }

    func applicationDidBecomeActive(application: UIApplication) {
        EventManager.sharedInstance.log(Application.DidBecomeActive)
    }

    func applicationWillTerminate(application: UIApplication) {
        EventManager.sharedInstance.log(Application.WillTerminate)
    }
}

