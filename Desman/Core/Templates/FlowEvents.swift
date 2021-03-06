//
//  FlowTypes.swift
//  Desman
//
//  Created by Matteo Gavagnin on 06/07/16.
//  Copyright © 2016 DIMENSION S.r.l. All rights reserved.
//

import UIKit

open class FlowType : DType {
    override open var type : String {
        return "init"
    }
}

@objc open class FlowApp : Event {
    public init () {
        
        super.init("Init", subtype: "AppVersion", desc: nil, value: nil)
        
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
        let buildNumber = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as! String
        
        self.desc = "\(version) (\(buildNumber))"
    }
}

@objc open class FlowDeviceName : Event {
    public init () {
        super.init("Init", subtype: "DeviceName", desc: nil, value: nil)
        self.desc = UIDevice.current.name
    }
}

@objc open class FlowDeviceType : Event {
    public init () {
        super.init("Init", subtype: "DeviceType", desc: nil, value: nil)
        
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8 , value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        
        self.desc = identifier
    }
}

@objc open class FlowDeviceID : Event {
    public init () {
        super.init("Init", subtype: "DeviceID", desc: nil, value: nil)
        
        if let identifierForVendor = UIDevice.current.identifierForVendor {
            self.desc = identifierForVendor.uuidString
        }
    }
}
