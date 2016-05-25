//
//  CDEvent+CoreDataProperties.swift
//  Desman
//
//  Created by Matteo Gavagnin on 18/11/15.
//  Copyright © 2015 DIMENSION S.r.l. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension CDEvent {

    @NSManaged var type: String
    @NSManaged var subtype: String
    @NSManaged var value: String
    @NSManaged var timestamp: NSDate
    @NSManaged var uuid: String
    @NSManaged var desc: String
    @NSManaged var id: String?
    @NSManaged var payload: NSData?
    @NSManaged var attachmentUrl: String?
    @NSManaged var sent: Bool

}
