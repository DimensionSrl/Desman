//
//  AppInfo.swift
//  Desman
//
//  Created by Matteo Gavagnin on 03/11/15.
//  Copyright © 2015 DIMENSION S.r.l. All rights reserved.
//

import Foundation

@objc public class AppInfo : Event {
    public init () {
        super.init(Application.Info)
        payload = infoDictionary
        attachment = App.currentAppIcon
    }
    
    var infoDictionary : [String : Coding] {
        return ["name": App.currentAppName]
    }
}

    