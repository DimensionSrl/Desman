//
//  UIViewController+Desman.swift
//  Desman
//
//  Created by Matteo Gavagnin on 13/11/15.
//  Copyright © 2015 DIMENSION S.r.l. All rights reserved.
//

import ObjectiveC

private var desmanControllerAssociationKey: UInt8 = 0

extension UIViewController {
    @IBInspectable var log: Bool {
        get {
            if let log = objc_getAssociatedObject(self, &desmanControllerAssociationKey) as? Bool {
                return log
            }
            return false
        }
        set(newValue) {
            objc_setAssociatedObject(self, &desmanControllerAssociationKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
        }
    }
}