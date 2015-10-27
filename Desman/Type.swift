//
//  Type.swift
//  Desman iOS Sample
//
//  Created by Matteo Gavagnin on 26/10/15.
//  Copyright © 2015 DIMENSION S.r.l. All rights reserved.
//

import Foundation

public class Type {
    required public init() {}
    static let Unknown = "Unknown"
    public var subtype : String = "Unknown"
    private var imageName : String = ""
    
    public var image : UIImage? {
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
    
    public var description : String {
        return "\(className.componentsSeparatedByString(".").last!) \(subtype)"
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