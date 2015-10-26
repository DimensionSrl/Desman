//
//  Event.swift
//  Desman iOS Sample
//
//  Created by Matteo Gavagnin on 19/10/15.
//  Copyright © 2015 DIMENSION S.r.l. All rights reserved.
//

import Foundation
import AdSupport

public class Event: NSCoder {
    public let type : String
    public let payload : [String : AnyObject]?
    public let timestamp : NSDate
    public var sent : Bool = false
    var id : String?
    var uuid : NSUUID?
    var user : String?
    let dateFormatter = NSDateFormatter()
    
    // This way we are able to track the current user and current device between app installations
    let currentUserIdentifier = ASIdentifierManager.sharedManager().advertisingIdentifier.UUIDString
    let currentAppIdentifier = NSBundle.mainBundle().bundleIdentifier
    
    func commonInit() {
        dateFormatter.dateStyle = .ShortStyle
        dateFormatter.timeStyle = .MediumStyle
        dateFormatter.locale = NSLocale.currentLocale()
    }
    
    public init?(dictionary: [String : AnyObject]) {
        guard let type = dictionary["type"] as? String else {
            self.type = ""
            self.timestamp = NSDate()
            self.payload = nil
            super.init()
            return nil
        }
        
        if let timeInterval = dictionary["timestamp"] as? NSTimeInterval {
            self.timestamp = NSDate(timeIntervalSince1970: timeInterval)
        } else {
            self.timestamp = NSDate()
        }
        
        if let payload = dictionary["payload"] as? [String : AnyObject] {
            self.payload = payload
        } else {
            self.payload = nil
        }
        
        if let id = dictionary["id"] as? String {
            self.id = id
        }
        
        if let uuid = dictionary["uuid"] as? String {
            self.uuid = NSUUID(UUIDString: uuid)
        }
        
        if let user = dictionary["user"] as? String {
            self.user = user
        }
        
        self.type = type
        super.init()
        self.commonInit()
    }
    
    public init(type: String) {
        self.type = type
        self.timestamp = NSDate()
        self.payload = nil
        self.uuid = NSUUID()
        super.init()
        self.commonInit()
    }
    
    public init(type: String, timestamp: NSDate) {
        self.type = type
        self.timestamp = timestamp
        self.payload = nil
        self.uuid = NSUUID()
        super.init()
        self.commonInit()
    }
    
    public init(type: String, timestamp: NSDate, user : String) {
        self.type = type
        self.timestamp = timestamp
        self.user = user
        self.payload = nil
        self.uuid = NSUUID()
        super.init()
        self.commonInit()
    }
    
    public init(type: String, timestamp: NSDate, payload : [String : AnyObject]) {
        self.type = type
        self.timestamp = timestamp
        self.payload = payload
        self.uuid = NSUUID()
        super.init()
        self.commonInit()
    }
    
    public init(type: String, timestamp: NSDate, payload : [String : AnyObject], user : String) {
        self.type = type
        self.timestamp = timestamp
        self.payload = payload
        self.uuid = NSUUID()
        self.user = user
        super.init()
        self.commonInit()
    }
    
    public convenience init(coder decoder: NSCoder) {
        let type = decoder.decodeObjectForKey("type") as! String
        if let timestamp = decoder.decodeObjectForKey("timestamp") as? NSDate {
            if let payloadData = decoder.decodeObjectForKey("payload") as? NSData {
                
                if let payload = NSKeyedUnarchiver.unarchiveObjectWithData(payloadData) as? [String : AnyObject] {
                    self.init(type: type, timestamp: timestamp, payload: payload)
                } else {
                    self.init(type: type, timestamp: timestamp)
                }
            } else {
                self.init(type: type, timestamp: timestamp)
            }
        } else {
            self.init(type: type)
        }
        if let id = decoder.decodeObjectForKey("id") as? String {
            self.id = id
        }
        if let uuid = decoder.decodeObjectForKey("uuid") as? String {
            self.uuid = NSUUID(UUIDString: uuid)
        }
        if let user = decoder.decodeObjectForKey("user") as? String {
            self.user = user
        }
        self.sent = decoder.decodeBoolForKey("sent")
        self.commonInit()
    }

    func encodeWithCoder(coder: NSCoder) {
        coder.encodeObject(type, forKey: "type")
        coder.encodeObject(timestamp, forKey: "timestamp")
        coder.encodeObject(payload, forKey: "payload")
        coder.encodeObject(id, forKey: "id")
        coder.encodeObject(uuid, forKey: "uuid")
        coder.encodeObject(user, forKey: "user")
        coder.encodeBool(sent, forKey: "sent")
    }
    
    var dictionary : [String : AnyObject] {
        var dict = [String : AnyObject]()
        dict["type"] = type
        dict["timestamp"] = timestamp.timeIntervalSince1970
        dict["uuid"] = identifier
        dict["user"] = userIdentifier
        dict["app"] = currentAppIdentifier
        if let id = self.id {
            dict["id"] = id
        }
        if let payload = self.payload {
            dict["payload"] = payload
        }

        return dict
    }
    
    var data : NSData? {
        do {
            let dictionaryIncapsulated = ["event": dictionary]
            return try NSJSONSerialization.dataWithJSONObject(dictionaryIncapsulated, options: .PrettyPrinted)
        } catch let error {
            print("Desman Event, cannot create json representation \(error) - \(self.dictionary)")
            return nil
        }
    }
    
    public var identifier : String {
        if let uuid = self.uuid {
            return uuid.UUIDString
        } else {
            self.uuid = NSUUID()
            return self.uuid!.UUIDString
        }
    }
    
    public var userIdentifier : String {
        if let user = self.user {
            return "\(currentUserIdentifier) - \(user)"
        }
        return currentUserIdentifier
    }
    
    override public var description : String {
        return "\n\(dateFormatter.stringFromDate(timestamp)) (\(timestamp.timeIntervalSince1970)) - \(type) - \(sent)"
    }
    
    override public func isEqual(object: AnyObject?) -> Bool {
        if let object = object as? Event {
            return hash == object.hash
        }
        return false
    }
    
    override public var hash: Int {
        return "\(type)-\(timestamp.timeIntervalSince1970)-\(identifier)-\(userIdentifier)".hashValue
    }
}