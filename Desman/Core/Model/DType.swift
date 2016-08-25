//
//  DType.swift
//  Desman iOS Sample
//
//  Created by Matteo Gavagnin on 26/10/15.
//  Copyright © 2015 DIMENSION S.r.l. All rights reserved.
//

import Foundation
import UIKit

@objc open class DType : NSObject {
    override required public init() {}
    static let Unknown = DType(subtype: "Unknown")
    open var subtype : String = "Unknown"
    var imageName : String = ""
    
    open var image : UIImage? {
        var name = imageName
        if imageName == "" {
            name = "Unknown"
        }
        if let classForImage = NSClassFromString("Desman.EventsTableViewController") {
            if #available(iOS 8.0, *) {
                return UIImage(named: name, in: Bundle(for: classForImage), compatibleWith: nil)
            } else {
                return UIImage()
                // Fallback on earlier versions
            }
        }
        return nil
    }
    
    var rawValue: String {
        return "\(className).\(subtype)"
    }
    
    open var className : String {
        return NSStringFromClass(type(of: self))
    }
    
    open var dictionary : [String : Any] {
        return ["type": className as AnyObject, "subtype": self.subtype]
    }
    
    public init(subtype : String) {
        self.subtype = subtype
    }
    
    override open var description : String {
        return "\(type) \(subtype)"
    }
    
    open var type : String {
        let dotString = "."
        return "\(className.components(separatedBy: dotString).last!)"
    }
    
    class open func new(_ dictionary : [String : String]) -> AnyObject? {
        if let typeString = dictionary["type"], let subtypeString = dictionary["subtype"] {
            if let TypeClass = NSClassFromString(typeString) as? DType.Type {
                let type = TypeClass.init()
                type.subtype = subtypeString
                return type
            } else {
                // Generic type if doesn't match with a known class
                let type = DType()
                type.subtype = subtypeString
                return type
            }
        }
        return nil
    }
    
    class open func new(_ type: String, subtype: String) -> AnyObject? {
        if let TypeClass = NSClassFromString(type) as? DType.Type {
            let type = TypeClass.init()
            type.subtype = subtype
            return type
        } else {
            // Generic type if doesn't match with a known class
            let type = DType()
            type.subtype = subtype
            return type
        }
    }
}

open class AppCycle : DType {
    open static let WillEnterForeground = AppCycle(subtype: "WillEnterForeground")
    open static let DidFinishLaunching = AppCycle(subtype: "DidFinishLaunching")
    open static let DidBecomeActive = AppCycle(subtype: "DidBecomeActive")
    open static let WillResignActive = AppCycle(subtype: "WillResignActive")
    open static let DidEnterBackground = AppCycle(subtype: "DidEnterBackground")
    open static let WillTerminate = AppCycle(subtype: "WillTerminate")
    open static let DidRegisterForRemoteNotifications = AppCycle(subtype: "DidRegisterForRemoteNotifications")
    open static let DidFailToRegisterForRemoteNotifications = AppCycle(subtype: "DidFailToRegisterForRemoteNotifications")
    open static let LogEnable = AppCycle(subtype: "LogEnable")
    open static let LogDisable = AppCycle(subtype: "LogDisable")
    open static let Info = AppCycle(subtype: "Info")

    override var imageName : String {
        get {
            if subtype == "DidFinishLaunching" {
                 return "App Launch"
            } else {
                 return "App"
            }
        }
        set { self.imageName = newValue }
    }
}

open class Notification : DType {
    override var imageName : String {
        get { return "Notification" }
        set { self.imageName = newValue }
    }
}

open class Crash : DType {
    override var imageName : String {
        get { return "Error" }
        set { self.imageName = newValue }
    }
}

open class Error : DType {
    override var imageName : String {
        get { return "Error" }
        set { self.imageName = newValue }
    }
}

open class Warning : DType {
    override var imageName : String {
        get { return "Warning" }
        set { self.imageName = newValue }
    }
}

open class Info : DType {
    override var imageName : String {
        get { return "Info" }
        set { self.imageName = newValue }
    }
}

open class Table : DType {
    open static let DidSelectRow = Table(subtype: "DidSelectRow")
    override var imageName : String {
        get { return "Table View Controller" }
        set { self.imageName = newValue }
    }
}

open class Controller : DType {
    open static let ViewWillAppear = Controller(subtype: "ViewWillAppear")
    open static let ViewDidAppear = Controller(subtype: "ViewDidAppear")
    open static let ViewWillDisappear = Controller(subtype: "ViewWillDisappear")
    open static let Screenshot = Controller(subtype: "Screenshot")
    override var imageName : String {
        get { return "View Controller" }
        set { self.imageName = newValue }
    }
    
    internal func imageWithController(_ controller: String) {
        // TODO: return a different image based on the controller type
        // Navigation, table, collection, generic, alert, split view
    }
}

open class Beacon : DType {
    open static let DidRangeBeacons = Beacon(subtype: "DidRangeBeacons")
    open static let StartRanging = Beacon(subtype: "StartRanging")
    open static let StopRanging = Beacon(subtype: "StopRanging")
    open static let StopBrieflyRanging = Beacon(subtype: "StopBrieflyRanging")
    open static let RangingDidFail = Beacon(subtype: "RangingDidFail")

    override var imageName : String {
        get { return "Beacon" }
        set { self.imageName = newValue }
    }
}

open class Region : DType {
    open static let StartRegionMonitoring = Region(subtype: "StartRegionMonitoring")
    open static let MonitorDidFail = Region(subtype: "MonitorDidFail")
    open static let DidEnter = Region(subtype: "DidEnter")
    open static let DidExit = Region(subtype: "DidExit")
    open static let DidStartMonitoring = Region(subtype: "DidStartMonitoring")
    open static let DidDetermineState = Region(subtype: "DidDetermineState")
    open static let DidChangeAuthorization = Region(subtype: "DidChangeAuthorization")
    
    override var imageName : String {
        get { return "Beacon" }
        set { self.imageName = newValue }
    }
}

open class Location : DType {
    open static let DidFail = Location(subtype: "DidFail")
    open static let DidChangeAuthorization = Location(subtype: "DidChangeAuthorization")
    
    override var imageName : String {
        get { return "Beacon" }
        set { self.imageName = newValue }
    }
}

open class Connection : DType {
    open static let DidFail = Connection(subtype: "DidFail")
    open static let DidLoad = Connection(subtype: "DidLoad")
    
    override var imageName : String {
        get { return "Safari" }
        set { self.imageName = newValue }
    }
}

open class Device : DType {
    open static let Hardware = Device(subtype: "Hardware")
    open static let User = Device(subtype: "User")
    
    override var imageName : String {
        get { return "Device" }
        set { self.imageName = newValue }
    }
}

open class Feedback : DType {
    open static let User = Feedback(subtype: "User")
    
    override var imageName : String {
        get { return "User" }
        set { self.imageName = newValue }
    }
}

open class Action : DType {
    open static let Button = Action(subtype: "Button")
    
    override var imageName : String {
        get { return "Action Button" }
        set { self.imageName = newValue }
    }
}
