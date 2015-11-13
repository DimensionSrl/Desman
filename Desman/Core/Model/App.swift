//
//  App.swift
//  Desman
//
//  Created by Matteo Gavagnin on 31/10/15.
//  Copyright © 2015 DIMENSION S.r.l. All rights reserved.
//

public class App: NSCoder {
    public let bundle : String
    public var name : String?
    public var iconUrl : NSURL?
    
    public init(bundle: String) {
        self.bundle = bundle
    }

    public init(bundle: String, name: String) {
        self.bundle = bundle
        self.name = name
    }
    
    public init(bundle: String, name: String, icon: String) {
        self.bundle = bundle
        self.name = name
        self.iconUrl = NSURL(string: icon)
    }
    
    public init?(dictionary: [String : Coding]) {
        guard let bundle = dictionary["bundle"] as? String else {
            self.bundle = ""
            super.init()
            return nil
        }
        
        if let name = dictionary["name"] as? String {
            self.name = name
        }
        
        if let icon = dictionary["icon"] as? String {
            self.iconUrl = NSURL(string: icon)
        }
        
        self.bundle = bundle
        super.init()
    }
    
    override public func isEqual(object: AnyObject?) -> Bool {
        if let object = object as? App {
            return hash == object.hash
        }
        return false
    }
    
    override public var hash: Int {
        return "\(bundle)".hashValue
    }
    
    override public var description : String {
        return "App: \(bundle)"
    }
    
    public class var currentAppIcon : NSData? {
        let infoPlist : NSDictionary = NSBundle.mainBundle().infoDictionary!
        if let icon = infoPlist.valueForKeyPath("CFBundleIcons.CFBundlePrimaryIcon.CFBundleIconFiles")?.lastObject as? String {
            if let image = UIImage(named: icon) {
                let data = UIImagePNGRepresentation(image)
                return data
                
            }
        }
        return nil
    }
    
    public class var currentAppName : String {
        let infoPlist : NSDictionary = NSBundle.mainBundle().infoDictionary!
        if let name = infoPlist.valueForKeyPath("CFBundleName") as? String {
            return name
        }
        return "Unknown"
    }
    
    public var title : String {
        if let name = name {
            return name
        }
        return bundle
    }
}
