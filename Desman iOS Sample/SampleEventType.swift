//
//  SampleEventType.swift
//  Desman iOS Sample
//
//  Created by Matteo Gavagnin on 26/10/15.
//  Copyright © 2015 DIMENSION S.r.l. All rights reserved.
//

import UIKit
import Desman

enum SampleEventType : EventType {
    case TestEvent = "TestEvent"
    
    var image : UIImage? {
        if let img = super.image {
            return img
        } else {
            var name = ""
            switch self {
            case .TestEvent:
                name = "Test"
                break
            }
            return UIImage(named: name)
        }
    }
}