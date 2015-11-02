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
    public let device : String
    
    public init(uuid: String, device: String) {
        self.uuid = uuid
        self.device = device
    }
    
    public init?(dictionary: [String : Coding]) {
        guard let uuid = dictionary["user"] as? String, let device = dictionary["device"] as? String else {
            self.uuid = ""
            self.device = ""
            super.init()
            return nil
        }
        
        self.uuid = uuid
        self.device = device
        super.init()
    }
    
    override public func isEqual(object: AnyObject?) -> Bool {
        if let object = object as? User {
            return hash == object.hash
        }
        return false
    }
    
    override public var hash: Int {
        return "\(uuid)\(device)".hashValue
    }
    
    override public var description : String {
        return "User: \(device) - \(uuid)"
    }
}