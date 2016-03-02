//
//  Event.swift
//  Desman iOS Sample
//
//  Created by Matteo Gavagnin on 19/10/15.
//  Copyright © 2015 DIMENSION S.r.l. All rights reserved.
//

import Foundation
import AdSupport
import UIKit
import CoreData

public typealias Coding = protocol<NSCoding>

public let currentUserIdentifier = UIDevice.currentDevice().identifierForVendor!.UUIDString
public let currentAppIdentifier = NSBundle.mainBundle().bundleIdentifier
public let currentDeviceName = UIDevice.currentDevice().name

public class Event: NSCoder {
    public let type : Type
    public var value: String?
    public var payload : [String : Coding]?
    public var timestamp : NSDate
    public var sent : Bool = false
    var uploading : Bool = false
    public var attachment : NSData?
    public var attachmentUrl : NSURL?
    
    // TODO: support remote attachment url with caching
    
    var id : String?
    public var uuid : NSUUID?
    public let dateFormatter = NSDateFormatter()
    
    func commonInit() {
        dateFormatter.dateStyle = .ShortStyle
        dateFormatter.timeStyle = .MediumStyle
        dateFormatter.locale = NSLocale.currentLocale()
    }
    
    public init?(dictionary: [String : Coding]) {
        guard let typeString = dictionary["type"] as? String, subtypeString = dictionary["subtype"] as? String, type = Type.new(typeString, subtype: subtypeString) as? Type else {
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
        
        if let payload = dictionary["payload"] as? [String : Coding] {
            self.payload = payload
        }
        
        if let id = dictionary["id"] as? String {
            self.id = id
        }
        
        if let value = dictionary["value"] as? String {
            self.value = value
        }
        
        if let uuid = dictionary["uuid"] as? String {
            self.uuid = NSUUID(UUIDString: uuid)
        }
        
        if let attachmentString = dictionary["attachment"] as? String {
            self.attachmentUrl = NSURL(string: attachmentString)
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
    
    public init(_ type: Type, value: String) {
        self.type = type
        self.value = value
        self.timestamp = NSDate()
        self.uuid = NSUUID()
        super.init()
        self.commonInit()
    }

    public init(type: Type, value: String, payload: [String : Coding]) {
        self.type = type
        self.timestamp = NSDate()
        self.payload = payload
        self.value = value
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

    
    public init(type: Type, payload: [String : Coding], attachment: NSData) {
        self.type = type
        self.timestamp = NSDate()
        self.payload = payload
        self.uuid = NSUUID()
        self.attachment = attachment
        super.init()
        self.commonInit()
    }
    
    public init(type: Type, value: String, payload: [String : Coding], attachment: NSData) {
        self.type = type
        self.value = value
        self.timestamp = NSDate()
        self.payload = payload
        self.uuid = NSUUID()
        self.attachment = attachment
        super.init()
        self.commonInit()
    }
    
    init(cdevent: CDEvent) {
        if let type = Type.new(cdevent.type, subtype: cdevent.subtype) as? Type {
            self.type = type
        } else {
            self.type = Type.Unknown
        }
        self.timestamp = cdevent.timestamp
        
        if let p = cdevent.payload, let payload = NSKeyedUnarchiver.unarchiveObjectWithData(p) as? [String : Coding] {
            self.payload = payload
        }
        if let id = cdevent.id {
            self.id = id
        }
        
        self.value = cdevent.value
        
        self.uuid = NSUUID(UUIDString: cdevent.uuid)
        
        if let url = cdevent.attachmentUrl,  let attachmentUrl = NSURL(string: url) {
            self.attachmentUrl = attachmentUrl
        }
        self.sent = cdevent.sent
        super.init()
        self.commonInit()
    }
    
    func saveCDEvent() {
        let event = CoreDataSerializerManager.sharedInstance.event(self.identifier)
        event.type = self.type.className
        event.subtype = self.type.subtype
        if let payload = self.payload {
            event.payload = NSKeyedArchiver.archivedDataWithRootObject(payload)
        }
        event.uuid = identifier
        if let value = value {
            event.value = value
        }
        event.sent = self.sent
        event.timestamp = self.timestamp
        if let attachmentUrl = self.attachmentUrl {
            event.attachmentUrl = attachmentUrl.absoluteString
        }
        if let id = self.id {
            event.id = id
        }
        CoreDataSerializerManager.sharedInstance.save()
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
        if let value = decoder.decodeObjectForKey("value") as? String {
            self.value = value
        }

        if let uuid = decoder.decodeObjectForKey("uuid") as? String {
            self.uuid = NSUUID(UUIDString: uuid)
        }
        if let attachmentString = decoder.decodeObjectForKey("attachment") as? String {
            // TODO: support file url or remote url
            self.attachmentUrl = NSURL(string: attachmentString)
        }

        self.sent = decoder.decodeBoolForKey("sent")
        self.commonInit()
    }

    func encodeWithCoder(coder: NSCoder) {
        coder.encodeObject(type.dictionary, forKey: "type")
        coder.encodeObject(timestamp, forKey: "timestamp")
        coder.encodeObject(value, forKey: "value")
        coder.encodeObject(payload, forKey: "payload")
        coder.encodeObject(id, forKey: "id")
        coder.encodeObject(uuid, forKey: "uuid")
        coder.encodeObject(attachmentUrl, forKey: "attachment")
        coder.encodeBool(sent, forKey: "sent")
    }
    
    var dictionary : [String : Coding] {
        var dict = [String : Coding]()
        dict["type"] = type.className
        dict["subtype"] = type.subtype
        dict["timestamp"] = timestamp.timeIntervalSince1970
        dict["uuid"] = identifier
        dict["user"] = userIdentifier
        dict["app"] = currentAppIdentifier
        if let value = self.value {
            dict["value"] = value
        }
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
        return "\(currentUserIdentifier)"
    }
    
    override public var description : String {
        if let payload = payload {
            return "\(dateFormatter.stringFromDate(timestamp)) - \(title) \(payload)"
        } else {
            return "\(dateFormatter.stringFromDate(timestamp)) - \(title)"
        }
    }
    
    public var title : String {
        if self.type.className == "Desman.Controller" {
            if let payload = self.payload, let controllerName = payload["controller"] as? String {
                return "\(controllerName) \(type.subtype)"
            }
        }
        if self.type.className == "Desman.Action" && self.type.subtype == Action.Button.subtype {
            if let payload = self.payload, let buttonName = payload["button"] as? String {
                return "\(buttonName) \(type.subtype)"
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