//
//  App.swift
//  Desman
//
//  Created by Matteo Gavagnin on 31/10/15.
//  Copyright © 2015 DIMENSION S.r.l. All rights reserved.
//

public class App: NSCoder {
    public let bundle : String
    
    public init(bundle: String) {
        self.bundle = bundle
    }
    
    public init?(dictionary: [String : Coding]) {
        guard let bundle = dictionary["bundle"] as? String else {
            self.bundle = ""
            super.init()
            return nil
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
    
    public class func currentAppIcon() -> UIImage? {
        let infoPlist : NSDictionary = NSBundle.mainBundle().infoDictionary!
        if let icon = infoPlist.valueForKeyPath("CFBundleIcons.CFBundlePrimaryIcon.CFBundleIconFiles")?.lastObject as? String {
            let image = UIImage(named: icon)
            return image
        }
        return nil
    }
}
