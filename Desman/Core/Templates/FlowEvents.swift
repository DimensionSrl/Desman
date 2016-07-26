//
//  FlowTypes.swift
//  Desman
//
//  Created by Matteo Gavagnin on 06/07/16.
//  Copyright © 2016 DIMENSION S.r.l. All rights reserved.
//

import UIKit

public class FlowType : Type {
    override public var type : String {
        return "init"
    }
}

@objc public class FlowApp : Event {
    public init () {
        
        super.init("Init", subtype: "AppVersion", desc: nil, value: nil)
        
        let version = NSBundle.mainBundle().objectForInfoDictionaryKey("CFBundleShortVersionString") as! String
        let buildNumber = NSBundle.mainBundle().objectForInfoDictionaryKey("CFBundleVersion") as! String
        
        self.desc = "\(version) (\(buildNumber))"
    }
}

@objc public class FlowDeviceName : Event {
    public init () {
        super.init("Init", subtype: "DeviceName", desc: nil, value: nil)
        self.desc = UIDevice.currentDevice().name
    }
}

@objc public class FlowDeviceType : Event {
    public init () {
        super.init("Init", subtype: "DeviceType", desc: nil, value: nil)
        
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8 where value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        
        self.desc = identifier
    }
}

@objc public class FlowDeviceID : Event {
    public init () {
        super.init("Init", subtype: "DeviceID", desc: nil, value: nil)
        
        if let identifierForVendor = UIDevice.currentDevice().identifierForVendor {
            self.desc = identifierForVendor.UUIDString
        }
    }
}