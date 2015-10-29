//
//  Info.swift
//  Desman
//
//  Created by Matteo Gavagnin on 29/10/15.
//  Copyright © 2015 DIMENSION S.r.l. All rights reserved.
//

import Foundation

@objc public class Info : Event {
    public init () {
        super.init(Type(subtype: "info"))
        payload = infoDictionary
    }
    
    var infoDictionary : [String : AnyObject] {
        var info = [String : AnyObject]()
        
        var appData = [String : NSObject]()
        appData["bundleIdentifier"] = NSBundle.mainBundle().bundleIdentifier
        appData["shortVersion"] = NSBundle.mainBundle().objectForInfoDictionaryKey("CFBundleShortVersionString") as? NSObject
        appData["version"] = NSBundle.mainBundle().objectForInfoDictionaryKey("CFBundleVersion") as? NSObject
        
        info["app"] = appData
        
        var deviceData = [String : AnyObject]()
        deviceData["vendorIdentifier"] = UIDevice.currentDevice().identifierForVendor!.UUIDString
        deviceData["systemName"] = UIDevice.currentDevice().systemName
        deviceData["systemVersion"] = UIDevice.currentDevice().systemVersion
        deviceData["model"] = UIDevice.currentDevice().model
        
        info["device"] = deviceData
        
        var envData = [String : AnyObject]()
        envData["locale"] = NSLocale.currentLocale().localeIdentifier
        envData["language"] = NSLocale.preferredLanguages().first
        envData["timezone"] = NSTimeZone.defaultTimeZone().name
        envData["timestamp"] = NSDate().timeIntervalSince1970
        
        info["env"] = envData
        
        return info
    }
}