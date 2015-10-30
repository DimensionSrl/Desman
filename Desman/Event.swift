//
//  Event.swift
//  Desman iOS Sample
//
//  Created by Matteo Gavagnin on 19/10/15.
//  Copyright © 2015 DIMENSION S.r.l. All rights reserved.
//

import Foundation
import AdSupport

public typealias Coding = protocol<NSCoding>

// This way we are able to track the current user and current device between app installations
let currentUserIdentifier = ASIdentifierManager.sharedManager().advertisingIdentifier.UUIDString
let currentAppIdentifier = NSBundle.mainBundle().bundleIdentifier
let currentDeviceName = UIDevice.currentDevice().name

public class Event: NSCoder {
    public let type : Type
    public var payload : [String : AnyObject]?
    public var timestamp : NSDate
    public var sent : Bool = false
    var id : String?
    var uuid : NSUUID?
    let dateFormatter = NSDateFormatter()
    
    func commonInit() {
        dateFormatter.dateStyle = .ShortStyle
        dateFormatter.timeStyle = .MediumStyle
        dateFormatter.locale = NSLocale.currentLocale()
    }
    
    public init?(dictionary: [String : Coding]) {
        guard let typeDictionary = dictionary["type"] as? [String: String], type = Type.new(typeDictionary) as? Type else {
            self.type = Type()
            self.timestamp = NSDate()
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
        }
        
        if let id = dictionary["id"] as? String {
            self.id = id
        }
        
        if let uuid = dictionary["uuid"] as? String {
            self.uuid = NSUUID(UUIDString: uuid)
        }
        
        self.type = type
        super.init()
        self.commonInit()
    }
    
    public init(_ type: Type) {
        self.type = type
        self.timestamp = NSDate()
        self.uuid = NSUUID()
        super.init()
        self.commonInit()
    }
    
    public init(type: Type, payload: [String : Coding]) {
        self.type = type
        self.timestamp = NSDate()
        self.payload = payload
        self.uuid = NSUUID()
        super.init()
        self.commonInit()
    }
    
    public convenience init(coder decoder: NSCoder) {
        if let typeDictionary = decoder.decodeObjectForKey("type") as? [String : String], type = Type.new(typeDictionary) as? Type  {
            if let timestamp = decoder.decodeObjectForKey("timestamp") as? NSDate {
                if let payloadData = decoder.decodeObjectForKey("payload") as? NSData {
                    if let payload = NSKeyedUnarchiver.unarchiveObjectWithData(payloadData) as? [String : Coding] {
                        self.init(type: type, payload: payload)
                        self.timestamp = timestamp
                    } else {
                        self.init(type)
                        self.timestamp = timestamp
                    }
                } else {
                    self.init(type)
                    self.timestamp = timestamp
                }
            } else {
                self.init(type)
            }
        
        } else {
            self.init(Type())
        }
        
        if let id = decoder.decodeObjectForKey("id") as? String {
            self.id = id
        }
        if let uuid = decoder.decodeObjectForKey("uuid") as? String {
            self.uuid = NSUUID(UUIDString: uuid)
        }
        self.sent = decoder.decodeBoolForKey("sent")
        self.commonInit()
    }

    func encodeWithCoder(coder: NSCoder) {
        coder.encodeObject(type.dictionary, forKey: "type")
        coder.encodeObject(timestamp, forKey: "timestamp")
        coder.encodeObject(payload, forKey: "payload")
        coder.encodeObject(id, forKey: "id")
        coder.encodeObject(uuid, forKey: "uuid")
        coder.encodeBool(sent, forKey: "sent")
    }
    
    var dictionary : [String : Coding] {
        var dict = [String : Coding]()
        dict["type"] = type.description
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
        return "\(currentUserIdentifier) - \(currentDeviceName)"
    }
    
    override public var description : String {
        return "\n\(dateFormatter.stringFromDate(timestamp)) (\(timestamp.timeIntervalSince1970)) - \(type) - \(sent)"
    }
    
    public var title : String {
        if self.type.className == "Desman.Controller" {
            if let payload = self.payload, let controllerName = payload["controller"] as? String {
                return "\(controllerName) \(type.subtype)"
            }
        }
        return type.description
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
    
    public var image : UIImage? {
        if let image = self.type.image {
            return image
        } else {
            return UIImage(named: "Unknown", inBundle: NSBundle(forClass: EventManager.self), compatibleWithTraitCollection: nil)
        }
    }
}