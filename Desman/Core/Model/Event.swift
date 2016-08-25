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

public let currentUserIdentifier = UIDevice.current.identifierForVendor!.uuidString
public let currentAppIdentifier = Bundle.main.bundleIdentifier
public let currentDeviceName = UIDevice.current.name

open class Event: NSCoder {
    open let type : DType
    open var value: String?
    open var payload : [String : Any]?
    open var timestamp : Date
    open var sent : Bool = false
    var uploading : Bool = false
    open var attachment : Data?
    open var attachmentUrl : URL?
    open var desc : String?
    open var typeString : String?
    
    // TODO: support remote attachment url with caching
    
    var id : String?
    open var uuid : UUID?
    open let dateFormatter = DateFormatter()
    
    func commonInit() {
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .medium
        dateFormatter.locale = NSLocale.current
    }
    
    public init?(dictionary: [String : Any]) {
        guard let typeString = dictionary["type"] as? String, let subtypeString = dictionary["subtype"] as? String, let type = DType.new(typeString, subtype: subtypeString) as? DType else {
            self.type = DType()
            self.timestamp = Date()
            super.init()
            return nil
        }
        
        if let timeInterval = dictionary["timestamp"] as? TimeInterval {
            self.timestamp = Date(timeIntervalSince1970: timeInterval)
        } else {
            self.timestamp = Date()
        }
        
        if let payload = dictionary["payload"] as? [String : Any] {
            self.payload = payload
        }
        
        if let id = dictionary["id"] as? String {
            self.id = id
        }
        
        if let desc = dictionary["desc"] as? String {
            self.desc = desc
        }
        
        if let value = dictionary["value"] as? String {
            self.value = value
        }
        
        if let uuid = dictionary["uuid"] as? String {
            self.uuid = UUID(uuidString: uuid)
        }
        
        if let attachmentString = dictionary["attachment"] as? String {
            self.attachmentUrl = URL(string: attachmentString)
        }
        
        self.type = type
        self.typeString = typeString
        super.init()
        self.commonInit()
    }
    
    public init(_ type: String, subtype: String, desc: String?, value: String?) {
        self.type = DType(subtype: subtype)
        self.typeString = type
        self.desc = desc
        self.value = value
        self.timestamp = Date()
        self.uuid = UUID()
        super.init()
        self.commonInit()
    }
    
    public init(_ type: DType) {
        self.type = type
        self.timestamp = Date()
        self.uuid = UUID()
        super.init()
        self.commonInit()
    }
    
    public init(_ type: DType, value: String) {
        self.type = type
        self.value = value
        self.timestamp = Date()
        self.uuid = UUID()
        super.init()
        self.commonInit()
    }
    
    public init(_ type: DType, desc: String) {
        self.type = type
        self.desc = desc
        self.timestamp = Date()
        self.uuid = UUID()
        super.init()
        self.commonInit()
    }
    
    public init(_ type: DType, value: String, desc: String) {
        self.type = type
        self.value = value
        self.timestamp = Date()
        self.uuid = UUID()
        self.desc = desc
        super.init()
        self.commonInit()
    }
    
    public init(_ type: DType, val: Double, desc: String) {
        self.type = type
        self.value = String(val)
        self.timestamp = Date()
        self.uuid = UUID()
        self.desc = desc
        super.init()
        self.commonInit()
    }

    public init(type: DType, value: String, payload: [String : Any]) {
        self.type = type
        self.timestamp = Date()
        if JSONSerialization.isValidJSONObject(payload) {
            self.payload = payload
        }
        self.value = value
        self.uuid = UUID()
        super.init()
        self.commonInit()
    }
    
    public init(type: DType, value: String, desc: String, payload: [String : Any]) {
        self.type = type
        self.timestamp = Date()
        if JSONSerialization.isValidJSONObject(payload) {
            self.payload = payload
        }
        self.value = value
        self.desc = desc
        self.uuid = UUID()
        super.init()
        self.commonInit()
    }

    public init(type: DType, val: Double, desc: String, payload: [String : Any]) {
        self.type = type
        self.timestamp = Date()
        if JSONSerialization.isValidJSONObject(payload) {
            self.payload = payload
        }
        self.value = String(describing: value)
        self.desc = desc
        self.uuid = UUID()
        super.init()
        self.commonInit()
    }

    
    public init(type: DType, payload: [String : Any]) {
        self.type = type
        self.timestamp = Date()
        if JSONSerialization.isValidJSONObject(payload) {
            self.payload = payload
        }
        self.uuid = UUID()
        super.init()
        self.commonInit()
    }

    
    public init(type: DType, payload: [String : Any], attachment: Data) {
        self.type = type
        self.timestamp = Date()
        if JSONSerialization.isValidJSONObject(payload) {
            self.payload = payload
        }
        self.uuid = UUID()
        self.attachment = attachment
        super.init()
        self.commonInit()
    }
    
    public init(type: DType, value: String, payload: [String : Any], attachment: Data) {
        self.type = type
        self.value = value
        self.timestamp = Date()
        if JSONSerialization.isValidJSONObject(payload) {
            self.payload = payload
        }
        self.uuid = UUID()
        self.attachment = attachment
        super.init()
        self.commonInit()
    }
    
    init(cdevent: CDEvent) {
        if let type = DType.new(cdevent.type, subtype: cdevent.subtype) as? DType {
            self.type = type
        } else {
            self.type = DType.Unknown
        }
        self.timestamp = cdevent.timestamp as Date
        
        if let p = cdevent.payload, let payload = NSKeyedUnarchiver.unarchiveObject(with: p as Data) as? [String : Any] {
            self.payload = payload
        }
        if let id = cdevent.id {
            self.id = id
        }
        
        self.value = cdevent.value
        self.desc = cdevent.desc
        
        self.uuid = UUID(uuidString: cdevent.uuid)
        
        self.typeString = cdevent.typeString
        
        if let url = cdevent.attachmentUrl,  let attachmentUrl = URL(string: url) {
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
            event.payload = NSKeyedArchiver.archivedData(withRootObject: payload)
        }
        event.uuid = identifier
        if let value = value {
            event.value = value
        }
        if let desc = desc {
            event.desc = desc
        }
        event.sent = self.sent
        event.timestamp = self.timestamp
        if let typeString = typeString {
            event.typeString = typeString
        }
        if let attachmentUrl = self.attachmentUrl {
            event.attachmentUrl = attachmentUrl.absoluteString
        }
        if let id = self.id {
            event.id = id
        }
        CoreDataSerializerManager.sharedInstance.save()
    }
    
    public convenience init(coder decoder: NSCoder) {
        if let typeDictionary = decoder.decodeObject(forKey: "type") as? [String : String], let type = DType.new(typeDictionary) as? DType  {
            if let timestamp = decoder.decodeObject(forKey: "timestamp") as? Date {
                if let payloadData = decoder.decodeObject(forKey: "payload") as? Data {
                    if let payload = NSKeyedUnarchiver.unarchiveObject(with: payloadData) as? [String : Any] {
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
            self.init(DType())
        }
        
        if let id = decoder.decodeObject(forKey: "id") as? String {
            self.id = id
        }
        if let value = decoder.decodeObject(forKey: "value") as? String {
            self.value = value
        }
        if let desc = decoder.decodeObject(forKey: "desc") as? String {
            self.desc = desc
        }
        
        if let typeString = decoder.decodeObject(forKey: "type_string") as? String {
            self.typeString = typeString
        }

        if let uuid = decoder.decodeObject(forKey: "uuid") as? String {
            self.uuid = UUID(uuidString: uuid)
        }
        if let attachmentString = decoder.decodeObject(forKey: "attachment") as? String {
            // TODO: support file url or remote url
            self.attachmentUrl = URL(string: attachmentString)
        }

        self.sent = decoder.decodeBool(forKey: "sent")
        self.commonInit()
    }

    func encodeWithCoder(_ coder: NSCoder) {
        coder.encode(type.dictionary, forKey: "type")
        coder.encode(timestamp, forKey: "timestamp")
        coder.encode(value, forKey: "value")
        coder.encode(desc, forKey: "desc")
        coder.encode(payload, forKey: "payload")
        coder.encode(id, forKey: "id")
        coder.encode(uuid, forKey: "uuid")
        coder.encode(attachmentUrl, forKey: "attachment")
        coder.encode(sent, forKey: "sent")
        coder.encode(typeString, forKey: "type_string")
    }
    
    var dictionary : [String : Any] {
        var dict = [String : Any]()
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
            if JSONSerialization.isValidJSONObject(payload) {
                dict["payload"] = self.payload
            }
        }
        if let desc = self.desc {
            dict["desc"] = desc
        }
        return dict
    }
    
    var flowDictionary : [String : Any] {
        var dict = [String : Any]()

        if let typeString = typeString {
            dict["category"] = typeString
        }
        
        dict["action"] = type.subtype
        dict["date"] = EventManager.shared.flowDateFormatter.string(from: timestamp)
        if let value = self.value, let doubleValue = Double(value) {
            dict["value"] = doubleValue
        }
        if let desc = self.desc {
            dict["label"] = desc
        }
        if let payload = self.payload {
            if JSONSerialization.isValidJSONObject(payload) {
                do {
                    let payloadData = try JSONSerialization.data(withJSONObject: payload, options: .prettyPrinted)
                    dict["payload"] = NSString(data: payloadData, encoding: String.Encoding.utf8.rawValue)
                } catch _ {
                    
                }
            }
        }
        return dict
    }
    
    var data : Data? {
        do {
            let dictionaryIncapsulated = ["event": dictionary]
            return try JSONSerialization.data(withJSONObject: dictionaryIncapsulated, options: .prettyPrinted)
        } catch let error {
            print("Desman Event, cannot create json representation \(error) - \(self.dictionary)")
            return nil
        }
    }
    
    open var identifier : String {
        if let uuid = self.uuid {
            return uuid.uuidString
        } else {
            self.uuid = UUID()
            return self.uuid!.uuidString
        }
    }
    
    open var userIdentifier : String {
        return "\(currentUserIdentifier)"
    }
    
    override open var description : String {
        if let payload = payload {
            return "\(dateFormatter.string(from: timestamp)) - \(title) \(payload)"
        } else if let value = value  {
            return "\(dateFormatter.string(from: timestamp)) - \(title) \(value)"
        } else {
            return "\(dateFormatter.string(from: timestamp)) - \(title)"
        }
    }
    
    open var title : String {
        if let desc = self.desc {
            return "\(type.subtype) \(desc)"
        }
        
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
        
        // If we have only one key in the payload and it's a string, print it
        if let payload = self.payload {
            let values = Array(payload.values)
            if values.count == 1 {
                if let value = values.first as? String {
                    return "\(value) - \(type.description)"
                }
            }
        }
        
        if let value = value {
            return "\(type.description) \(value)"
        }
        
        return type.description
    }
    
    override open func isEqual(_ object: Any?) -> Bool {
        if let object = object as? Event {
            return hash == object.hash
        }
        return false
    }
    
    override open var hash: Int {
        return "\(type)-\(timestamp.timeIntervalSince1970)-\(identifier)-\(userIdentifier)".hashValue
    }
    
    open var image : UIImage? {
        if let image = self.type.image {
            return image
        } else {
            if #available(iOS 8.0, *) {
                return UIImage(named: "Unknown", in: Bundle(for: EventManager.self), compatibleWith: nil)
            } else {
                return UIImage()
                // Fallback on earlier versions
            }
        }
    }
}
