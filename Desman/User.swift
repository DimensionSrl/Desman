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
    
    public init(uuid: String) {
        self.uuid = uuid
    }
    
    public init?(dictionary: [String : Coding]) {
        guard let uuid = dictionary["user"] as? String else {
            self.uuid = ""
            super.init()
            return nil
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
        return "User: \(uuid)"
    }
}