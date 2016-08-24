//
//  App.swift
//  Desman
//
//  Created by Matteo Gavagnin on 31/10/15.
//  Copyright © 2015 DIMENSION S.r.l. All rights reserved.
//

import Foundation
import UIKit

open class App: NSCoder {
    open let bundle : String
    open var name : String?
    open var iconUrl : URL?
    
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
        self.iconUrl = URL(string: icon)
    }
    
    public init?(dictionary: [String : Any]) {
        guard let bundle = dictionary["bundle"] as? String else {
            self.bundle = ""
            super.init()
            return nil
        }
        
        if let name = dictionary["name"] as? String {
            self.name = name
        }
        
        if let icon = dictionary["icon"] as? String {
            self.iconUrl = URL(string: icon)
        }
        
        self.bundle = bundle
        super.init()
    }
    
    override open func isEqual(_ object: Any?) -> Bool {
        if let object = object as? App {
            return hash == object.hash
        }
        return false
    }
    
    override open var hash: Int {
        return "\(bundle)".hashValue
    }
    
    override open var description : String {
        return "App: \(bundle)"
    }
    
    open class var currentAppIcon : Data? {
        _ = Bundle.main.infoDictionary!
        
        // FIXME: should convert to swift 3 syntax
//        if let icon = infoPlist.value(forKeyPath: "CFBundleIcons.CFBundlePrimaryIcon.CFBundleIconFiles")?.lastObject as? String {
//            if let image = UIImage(named: icon) {
//                let data = UIImagePNGRepresentation(image)
//                return data
//                
//            }
//        }
        return nil
    }
    
    open class var currentAppName : String {
        let infoPlist = Bundle.main.infoDictionary!
        if let name = infoPlist["CFBundleName"] as? String {
            return name
        }
        return "Unknown"
    }
    
    open var title : String {
        if let name = name {
            return name
        }
        return bundle
    }
}
