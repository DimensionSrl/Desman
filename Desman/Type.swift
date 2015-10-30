//
//  Type.swift
//  Desman iOS Sample
//
//  Created by Matteo Gavagnin on 26/10/15.
//  Copyright © 2015 DIMENSION S.r.l. All rights reserved.
//

import Foundation

@objc public class Type : NSObject {
    override required public init() {}
    static let Unknown = Type(subtype: "Unknown")
    public var subtype : String = "Unknown"
    private var imageName : String = ""
    
    public var image : UIImage? {
        if imageName == "" {
            return nil
        }
        return UIImage(named: imageName, inBundle: NSBundle(forClass: EventManager.self), compatibleWithTraitCollection: nil)
    }
    
    var rawValue: String {
        return "\(className).\(subtype)"
    }
    
    public var className : String {
        return NSStringFromClass(self.dynamicType)
    }
    
    public var dictionary : [String : AnyObject] {
        return ["type": className, "subtype": self.subtype]
    }
    
    public init(subtype : String) {
        self.subtype = subtype
    }
    
    override public var description : String {
        let dotString = "."
        return "\(className.componentsSeparatedByString(dotString).last!) \(subtype)"
    }
    
    class public func new(dictionary : [String : String]) -> AnyObject? {
        if let typeString = dictionary["type"], subtypeString = dictionary["subtype"] {
            if let TypeClass = NSClassFromString(typeString) as? Type.Type {
                let type = TypeClass.init()
                type.subtype = subtypeString
                return type
            }
        }
        return nil
    }
}

public class Application : Type {
    public static let WillEnterForeground = Application(subtype: "WillEnterForeground")
    public static let DidFinishLaunching = Application(subtype: "DidFinishLaunching")
    public static let DidBecomeActive = Application(subtype: "DidBecomeActive")
    public static let WillResignActive = Application(subtype: "WillResignActive")
    public static let DidEnterBackground = Application(subtype: "DidEnterBackground")
    public static let WillTerminate = Application(subtype: "WillTerminate")
    public static let DidRegisterForRemoteNotifications = Application(subtype: "DidRegisterForRemoteNotifications")
    public static let DidFailToRegisterForRemoteNotifications = Application(subtype: "DidFailToRegisterForRemoteNotifications")
    
    override var imageName : String {
        get { return "App" }
        set { self.imageName = newValue }
    }
}

public class Notification : Type {

}

public class Table : Type {
    public static let DidSelectRow = Table(subtype: "DidSelectRow")
    override var imageName : String {
        get { return "Table View Controller" }
        set { self.imageName = newValue }
    }
}

public class Controller : Type {
    public static let ViewWillAppear = Controller(subtype: "ViewWillAppear")
    public static let ViewDidAppear = Controller(subtype: "ViewDidAppear")
    override var imageName : String {
        get { return "View Controller" }
        set { self.imageName = newValue }
    }
}

public class Beacon : Type {
    public static let DidRangeBeacons = Beacon(subtype: "DidRangeBeacons")
    public static let StartRanging = Beacon(subtype: "StartRanging")
    public static let StopRanging = Beacon(subtype: "StopRanging")
    public static let StopBrieflyRanging = Beacon(subtype: "StopBrieflyRanging")
    public static let RangingDidFail = Beacon(subtype: "RangingDidFail")

    override var imageName : String {
        get { return "Beacon" }
        set { self.imageName = newValue }
    }
}

public class Region : Type {
    public static let StartRegionMonitoring = Region(subtype: "StartRegionMonitoring")
    public static let MonitorDidFail = Region(subtype: "MonitorDidFail")
    public static let DidEnter = Region(subtype: "DidEnter")
    public static let DidExit = Region(subtype: "DidExit")
    public static let DidStartMonitoring = Region(subtype: "DidStartMonitoring")
    public static let DidDetermineState = Region(subtype: "DidDetermineState")
    public static let DidChangeAuthorization = Region(subtype: "DidChangeAuthorization")
    
    override var imageName : String {
        get { return "Beacon" }
        set { self.imageName = newValue }
    }
}

public class Location : Type {
    public static let DidFail = Location(subtype: "DidFail")
    public static let DidDetermineState = Location(subtype: "DidDetermineState")
    public static let DidChangeAuthorization = Location(subtype: "DidChangeAuthorization")
    
    override var imageName : String {
        get { return "Beacon" }
        set { self.imageName = newValue }
    }
}

public class Connection : Type {
    public static let DidFail = Connection(subtype: "DidFail")
    public static let DidLoad = Connection(subtype: "DidLoad")
    
    override var imageName : String {
        get { return "Safari" }
        set { self.imageName = newValue }
    }
}

public class User : Type {
    public static let Feedback = User(subtype: "Feedback")
    public static let LogEnable = User(subtype: "LogEnable")
    public static let LogDisable = User(subtype: "LogDisable")
    public static let Info = User(subtype: "Info")
    
    override var imageName : String {
        get { return "User" }
        set { self.imageName = newValue }
    }
}