//
//  Info.swift
//  Desman
//
//  Created by Matteo Gavagnin on 29/10/15.
//  Copyright © 2015 DIMENSION S.r.l. All rights reserved.
//

import Foundation
import UIKit

@objc public class DeviceInfo : Event {
    public init () {
        super.init(Device.Hardware)
        payload = infoDictionary
    }
    
    var infoDictionary : [String : Coding] {
        var info = [String : Coding]()
        
        var appData = [String : NSObject]()
        appData["bundleIdentifier"] = NSBundle.mainBundle().bundleIdentifier
        appData["shortVersion"] = NSBundle.mainBundle().objectForInfoDictionaryKey("CFBundleShortVersionString") as? NSObject
        appData["version"] = NSBundle.mainBundle().objectForInfoDictionaryKey("CFBundleVersion") as? NSObject
        
        info["app"] = appData
        
        var deviceData = [String : AnyObject]()
        deviceData["vendorIdentifier"] = UIDevice.currentDevice().identifierForVendor!.UUIDString
        deviceData["systemName"] = UIDevice.currentDevice().systemName
        deviceData["systemVersion"] = UIDevice.currentDevice().systemVersion
        deviceData["model"] = modelName
        deviceData["name"] = UIDevice.currentDevice().name
        deviceData["idiom"] = idiom
        deviceData["batteryState"] = batteryState
        deviceData["batteryLevel"] = batteryLevel
        deviceData["availableSpace"] = availableSpace
        deviceData["totalSpace"] = totalSpace
        deviceData["usedMemory"] = usedMemory
        
        let physicalMemoryMB = NSProcessInfo.processInfo().physicalMemory / 1024 / 1024
        deviceData["totalMemory"] = NSNumber(unsignedLongLong: physicalMemoryMB)
        
        info["device"] = deviceData
        
        var envData = [String : AnyObject]()
        envData["locale"] = NSLocale.currentLocale().localeIdentifier
        envData["language"] = NSLocale.preferredLanguages().first
        envData["timezone"] = NSTimeZone.defaultTimeZone().name
        envData["timestamp"] = NSDate().timeIntervalSince1970
        
        info["env"] = envData
        
        // Detect wifi SSID? http://www.enigmaticape.com/blog/determine-wifi-enabled-ios-one-weird-trick
        
        return info
    }
    
    var batteryLevel : Int {
        UIDevice.currentDevice().batteryMonitoringEnabled = true
        let level = Double(UIDevice.currentDevice().batteryLevel)
        if level >= 0 {
            return Int(level * 100.0)
        } else {
            return -1
        }
    }
    
    var batteryState : String {
        UIDevice.currentDevice().batteryMonitoringEnabled = true
        switch UIDevice.currentDevice().batteryState {
        case .Unknown:
            return "Unknown"
        case .Unplugged:
            return "Unplugged"
        case .Charging:
            return "Charging"
        case .Full:
            return "Full"
        }
    }
    
    var idiom : String {
        let interfaceIdiom = UIDevice.currentDevice().userInterfaceIdiom
        switch interfaceIdiom {
        case .Phone:
            return "iPhone"
        case .Pad:
            return "iPad"
        case .Unspecified:
            return "Unspecified"
        default:
            return "Unknown"
        /* Requires Xcode 7.1
        case .TV:
            return "TV"
        */
        }
    }
    
    // Credits to HAN http://stackoverflow.com/a/26962452/616964
    var modelName: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8 where value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        
        switch identifier {
        case "iPod5,1":                                 return "iPod Touch 5"
        case "iPod7,1":                                 return "iPod Touch 6"
        case "iPhone3,1", "iPhone3,2", "iPhone3,3":     return "iPhone 4"
        case "iPhone4,1":                               return "iPhone 4s"
        case "iPhone5,1", "iPhone5,2":                  return "iPhone 5"
        case "iPhone5,3", "iPhone5,4":                  return "iPhone 5c"
        case "iPhone6,1", "iPhone6,2":                  return "iPhone 5s"
        case "iPhone7,2":                               return "iPhone 6"
        case "iPhone7,1":                               return "iPhone 6 Plus"
        case "iPhone8,1":                               return "iPhone 6s"
        case "iPhone8,2":                               return "iPhone 6s Plus"
        case "iPad2,1", "iPad2,2", "iPad2,3", "iPad2,4":return "iPad 2"
        case "iPad3,1", "iPad3,2", "iPad3,3":           return "iPad 3"
        case "iPad3,4", "iPad3,5", "iPad3,6":           return "iPad 4"
        case "iPad4,1", "iPad4,2", "iPad4,3":           return "iPad Air"
        case "iPad5,1", "iPad5,3", "iPad5,4":           return "iPad Air 2"
        case "iPad2,5", "iPad2,6", "iPad2,7":           return "iPad Mini"
        case "iPad4,4", "iPad4,5", "iPad4,6":           return "iPad Mini 2"
        case "iPad4,7", "iPad4,8", "iPad4,9":           return "iPad Mini 3"
        case "iPad5,1", "iPad5,2":                      return "iPad Mini 4"
        case "i386", "x86_64":                          return "Simulator"
        default:                                        return identifier
        }
    }
    
    
    var availableSpace : NSNumber {
        var availableSpace : NSNumber = 999999
        let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
        if let dictionary = try? NSFileManager.defaultManager().attributesOfFileSystemForPath(paths.last!) {
            if let freeSize = dictionary[NSFileSystemFreeSize] as? NSNumber {
                availableSpace = freeSize
            }
        } else {
            print("Error Obtaining System Memory Info:")
        }
        return availableSpace
    }

    var totalSpace : NSNumber {
        var totalSpace : NSNumber = 999999
        let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
        if let dictionary = try? NSFileManager.defaultManager().attributesOfFileSystemForPath(paths.last!) {
            if let freeSize = dictionary[NSFileSystemSize] as? NSNumber {
                totalSpace = freeSize
            }
        } else {
            print("Error Obtaining System Memory Info:")
        }
        return totalSpace
    }
    
    var usedMemory : NSNumber {
        var info = task_basic_info()
        var count = mach_msg_type_number_t(sizeofValue(info))/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(&info) {
            
            task_info(mach_task_self_,
                task_flavor_t(TASK_BASIC_INFO),
                task_info_t($0),
                &count)
        }
        
        if kerr == KERN_SUCCESS {
            let memoryUsedMB = info.resident_size / 1024 / 1024
            return NSNumber(unsignedInteger: memoryUsedMB)
        }
        return NSNumber(int: -1)
    }
}

    