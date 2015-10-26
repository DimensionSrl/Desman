//
//  EventType.swift
//  Desman iOS Sample
//
//  Created by Matteo Gavagnin on 26/10/15.
//  Copyright © 2015 DIMENSION S.r.l. All rights reserved.
//

import Foundation

public enum EventType : String {
    case ApplicationWillEnterForeground = "ApplicationWillEnterForeground"
    case ApplicationDidFinishLaunching = "ApplicationDidFinishLaunching"
    case ApplicationDidBecomeActive = "ApplicationDidBecomeActive"
    case ApplicationWillResignActive = "ApplicationWillResignActive"
    case ApplicationDidEnterBackground = "ApplicationDidEnterBackground"
    case ApplicationWillTerminate = "ApplicationWillTerminate"
    case ViewWillAppear = "ViewWillAppear"
    case DidSelectRow = "DidSelectRow"
    
    var image : UIImage? {
        var name = ""
        switch self {
        case .ApplicationDidFinishLaunching, .ApplicationWillEnterForeground, .ApplicationDidBecomeActive, .ApplicationWillResignActive, .ApplicationDidEnterBackground, .ApplicationWillTerminate:
            name = "App"
            break
        case .ViewWillAppear:
            name = "View Controller"
            break
        case .DidSelectRow:
            name = "Table View Controller"
            break
        }
        return UIImage(named: name, inBundle: NSBundle(forClass: EventManager.self), compatibleWithTraitCollection: nil)
    }
}