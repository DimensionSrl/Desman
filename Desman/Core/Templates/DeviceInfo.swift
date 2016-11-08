//
//  Info.swift
//  Desman
//
//  Created by Matteo Gavagnin on 29/10/15.
//  Copyright © 2015 DIMENSION S.r.l. All rights reserved.
//

import Foundation
import UIKit
import CoreBluetooth

@objc open class DeviceInfo : Event, CBPeripheralManagerDelegate {
    var bluetoothPeripheralManager : CBPeripheralManager?
    
    public init () {
        super.init(Device.Hardware)
        let options = [CBCentralManagerOptionShowPowerAlertKey:0]
        bluetoothPeripheralManager = CBPeripheralManager(delegate: self, queue: nil, options: options)
        
        payload = infoDictionary
    }
    
    var infoDictionary : [String : Any] {
        var info = [String : Any]()
        
        var appData = [String : Any]()
        appData["bundleIdentifier"] = Bundle.main.bundleIdentifier
        appData["shortVersion"] = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? NSObject
        appData["version"] = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? NSObject
        
        info["app"] = appData
        
        var deviceData = [String : Any]()
        deviceData["vendorIdentifier"] = UIDevice.current.identifierForVendor!.uuidString
        deviceData["systemName"] = UIDevice.current.systemName
        deviceData["systemVersion"] = UIDevice.current.systemVersion
        deviceData["model"] = modelName
        deviceData["name"] = UIDevice.current.name
        deviceData["idiom"] = idiom
        deviceData["batteryState"] = batteryState
        deviceData["batteryLevel"] = batteryLevel
        deviceData["availableSpace"] = availableSpace
        deviceData["totalSpace"] = totalSpace
        deviceData["usedMemory"] = usedMemory
        deviceData["totalMemory"] = physicalMemory
        
        deviceData["bluetoothState"] = bluetoothState
        
        info["device"] = deviceData
        
        var envData = [String : Any]()
        envData["locale"] = NSLocale.current.identifier
        envData["language"] = NSLocale.preferredLanguages.first
        envData["timezone"] = TimeZone.current.identifier
        envData["timestamp"] = Date().timeIntervalSince1970
        
        info["env"] = envData
        
        return info
    }
    
    var batteryLevel : Int {
        UIDevice.current.isBatteryMonitoringEnabled = true
        let level = Double(UIDevice.current.batteryLevel)
        if level >= 0 {
            return Int(level * 100.0)
        } else {
            return -1
        }
    }
    
    var batteryState : String {
        UIDevice.current.isBatteryMonitoringEnabled = true
        switch UIDevice.current.batteryState {
        case .unknown:
            return "Unknown"
        case .unplugged:
            return "Unplugged"
        case .charging:
            return "Charging"
        case .full:
            return "Full"
        }
    }
    
    var idiom : String {
        let interfaceIdiom = UIDevice.current.userInterfaceIdiom
        switch interfaceIdiom {
        case .phone:
            return "iPhone"
        case .pad:
            return "iPad"
        case .unspecified:
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
            guard let value = element.value as? Int8 , value != 0 else { return identifier }
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
        case "iPad6,7", "iPad6,8":                      return "iPad Pro"
        case "i386", "x86_64":                          return "Simulator"
        default:                                        return identifier
        }
    }
    
    
    var availableSpace : NSNumber {
        var availableSpace : NSNumber = 999999
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        if let dictionary = try? FileManager.default.attributesOfFileSystem(forPath: paths.last!) {
            if let freeSize = dictionary[FileAttributeKey.systemFreeSize] as? NSNumber {
                let freeSizeMB = freeSize.int64Value / 1024 / 1024
                availableSpace = NSNumber(value: freeSizeMB)
            }
        }
        return availableSpace
    }

    var totalSpace : NSNumber {
        var totalSpace : NSNumber = 999999
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        if let dictionary = try? FileManager.default.attributesOfFileSystem(forPath: paths.last!) {
            if let size = dictionary[FileAttributeKey.systemSize] as? NSNumber {
                let sizeMB = size.int64Value / 1024 / 1024
                totalSpace = NSNumber(value: sizeMB)
            }
        }
        return totalSpace
    }
    
    var usedMemory : NSNumber {
        // FIXME: convert to swift 3
//        var info = task_basic_info()
//        var count = mach_msg_type_number_t(MemoryLayout<task_basic_info>.size)/4
//        
//        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
//            
//            task_info(mach_task_self_,
//                task_flavor_t(TASK_BASIC_INFO),
//                task_info_t($0),
//                &count)
//        }
//        
//        if kerr == KERN_SUCCESS {
//            let memoryUsedMB = info.resident_size / 1024 / 1024
//            return NSNumber(value: UInt(memoryUsedMB))
//        }
        return NSNumber(value: -1)
    }
    
    var physicalMemory : NSNumber {
        let physicalMemoryMB = ProcessInfo.processInfo.physicalMemory / 1024 / 1024
        return NSNumber(value: physicalMemoryMB)
    }
    
    var bluetoothState : String {
        guard let state = bluetoothPeripheralManager?.state else { return "Unknown" }
        switch state {
        case .unknown:
            return "Unknown"
        case .resetting:
            return "Resetting"
        case .unsupported:
            return "Unsupported"
        case .unauthorized:
            return "Unauthorized"
        case .poweredOff:
            return "PoweredOff"
        case .poweredOn:
            return "PoweredOn"
        }
    }
    
    open func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
    
    }
}

    
