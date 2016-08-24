//
//  User.swift
//  Desman
//
//  Created by Matteo Gavagnin on 31/10/15.
//  Copyright © 2015 DIMENSION S.r.l. All rights reserved.
//

import UIKit

open class User: NSCoder {
    open let uuid : String
    open var name : String?
    open var imageUrl : URL?
    
    public init(uuid: String, name: String) {
        self.uuid = uuid
        self.name = name
    }
    
    public init(uuid: String, name: String, image: String) {
        self.uuid = uuid
        self.name = name
        self.imageUrl = URL(string: image)
    }
    
    public init?(dictionary: [String : Any]) {
        guard let uuid = dictionary["user"] as? String else {
            self.uuid = "Unknown"
            self.name = "Unknown"
            super.init()
            return
        }

        if let name = dictionary["name"] as? String {
            self.name = name
        }
        
        if let image = dictionary["image"] as? String {
            self.imageUrl = URL(string: image)
        }
        
        self.uuid = uuid
        super.init()
    }
    
    override open func isEqual(_ object: Any?) -> Bool {
        if let object = object as? User {
            return hash == object.hash
        }
        return false
    }
    
    override open var hash: Int {
        return "\(uuid)".hashValue
    }
    
    override open var description : String {
        return "User: \(name) - \(uuid)"
    }
    
    open var title : String {
        if let name = name {
            return name
        }
        return uuid
    }
}
