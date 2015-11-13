//
//  User.swift
//  Desman
//
//  Created by Matteo Gavagnin on 31/10/15.
//  Copyright © 2015 DIMENSION S.r.l. All rights reserved.
//

import UIKit

public class User: NSCoder {
    public let uuid : String
    public var name : String?
    public var imageUrl : NSURL?
    
    public init(uuid: String, name: String) {
        self.uuid = uuid
        self.name = name
    }
    
    public init(uuid: String, name: String, image: String) {
        self.uuid = uuid
        self.name = name
        self.imageUrl = NSURL(string: image)
    }
    
    public init?(dictionary: [String : Coding]) {
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
            self.imageUrl = NSURL(string: image)
        }
        
        self.uuid = uuid
        super.init()
    }
    
    override public func isEqual(object: AnyObject?) -> Bool {
        if let object = object as? User {
            return hash == object.hash
        }
        return false
    }
    
    override public var hash: Int {
        return "\(uuid)".hashValue
    }
    
    override public var description : String {
        return "User: \(name) - \(uuid)"
    }
    
    public var title : String {
        if let name = name {
            return name
        }
        return uuid
    }
}