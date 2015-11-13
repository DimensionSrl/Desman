//
//  UserInfo.swift
//  Desman
//
//  Created by Matteo Gavagnin on 03/11/15.
//  Copyright © 2015 DIMENSION S.r.l. All rights reserved.
//

import Foundation

@objc public class DeviceUserInfo : Event {
    public init () {
        super.init(Device.User)
        payload = infoDictionary
        // TODO: upload user photo if available
        // attachment = App.currentAppIcon
    }
    
    var infoDictionary : [String : Coding] {
        // Upload user name, not the device one
        return ["name": UIDevice.currentDevice().name]
    }
}