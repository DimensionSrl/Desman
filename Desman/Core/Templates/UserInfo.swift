//
//  UserInfo.swift
//  Desman
//
//  Created by Matteo Gavagnin on 03/11/15.
//  Copyright © 2015 DIMENSION S.r.l. All rights reserved.
//

import Foundation
import UIKit

@objc open class DeviceUserInfo : Event {
    public init () {
        super.init(Device.User)
        payload = infoDictionary
        // TODO: upload user photo if available
        // attachment = App.currentAppIcon
    }
    
    var infoDictionary : [String : Any] {
        // Upload user name, not the device one
        return ["name": UIDevice.current.name as NSCoding]
    }
}
