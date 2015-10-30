//
//  UIViewController-Swizzle.swift
//  Desman iOS Sample
//
//  Created by Matteo Gavagnin on 19/10/15.
//  Copyright © 2015 DIMENSION S.r.l. All rights reserved.
//

extension UIViewController {
    public override class func initialize() {
        struct Static {
            static var token: dispatch_once_t = 0
        }
        
        // make sure this isn't a subclass
        if self !== UIViewController.self {
            return
        }
        
        dispatch_once(&Static.token) {
            var originalSelector = Selector("viewWillAppear:")
            var swizzledSelector = Selector("desman_viewWillAppear:")
            
            var originalMethod = class_getInstanceMethod(self, originalSelector)
            var swizzledMethod = class_getInstanceMethod(self, swizzledSelector)
            
            let didAddMethodWill = class_addMethod(self, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod))
            
            if didAddMethodWill {
                class_replaceMethod(self, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod))
            } else {
                method_exchangeImplementations(originalMethod, swizzledMethod);
            }
            
            originalSelector = Selector("viewDidAppear:")
            swizzledSelector = Selector("desman_viewDidAppear:")
            
            originalMethod = class_getInstanceMethod(self, originalSelector)
            swizzledMethod = class_getInstanceMethod(self, swizzledSelector)
            
            let didAddMethodDid = class_addMethod(self, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod))
            
            if didAddMethodDid {
                class_replaceMethod(self, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod))
            } else {
                method_exchangeImplementations(originalMethod, swizzledMethod);
            }
            
            originalSelector = Selector("viewWillDisappear:")
            swizzledSelector = Selector("desman_viewWillDisappear:")
            
            originalMethod = class_getInstanceMethod(self, originalSelector)
            swizzledMethod = class_getInstanceMethod(self, swizzledSelector)
            
            let willDisappearAddMethodDid = class_addMethod(self, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod))
            
            if willDisappearAddMethodDid {
                class_replaceMethod(self, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod))
            } else {
                method_exchangeImplementations(originalMethod, swizzledMethod);
            }
        }
    }
    
    // MARK: - Method Swizzling
    
    func desman_viewWillAppear(animated: Bool) {
        if !isDesmanController && log {
            if EventManager.sharedInstance.swizzles.contains(Swizzle.ViewWillAppear) {
                let event = Event(type: Controller.ViewWillAppear, payload: ["controller": name])
                EventManager.sharedInstance.log(event)
            }
        }
        self.desman_viewWillAppear(animated)
    }
    
    func desman_viewDidAppear(animated: Bool) {
        if !isDesmanController && log {
            if EventManager.sharedInstance.swizzles.contains(Swizzle.ViewDidAppear) {
                let event = Event(type: Controller.ViewDidAppear, payload: ["controller": name])
                EventManager.sharedInstance.log(event)
            }
        }
        self.desman_viewDidAppear(animated)
    }
    
    func desman_viewWillDisappear(animated: Bool) {
        if !isDesmanController && log {
            if EventManager.sharedInstance.swizzles.contains(Swizzle.ViewWillDisappear) {
                let event = Event(type: Controller.ViewWillDisappear, payload: ["controller": name])
                EventManager.sharedInstance.log(event)
            }
        }
        self.desman_viewWillDisappear(animated)
    }
    
    var isDesmanController : Bool {
        if module == "Desman" {
            return true
        } else {
            return false
        }
    }
    
    var module : String {
        let className = NSStringFromClass(self.dynamicType)
        return "\(className.componentsSeparatedByString(".").first!)"
    }
    
    var name : String {
        let className = NSStringFromClass(self.dynamicType)
        return "\(className.componentsSeparatedByString(".").last!)"
    }
}

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