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
        }
    }
    
    // MARK: - Method Swizzling
    
    func desman_viewWillAppear(animated: Bool) {
        if EventManager.sharedInstance.swizzles.contains(Swizzle.ViewWillAppear) {
            let event = Event(type: Controller.ViewWillAppear, payload: ["controller": self.description])
            EventManager.sharedInstance.log(event)
        }
        self.desman_viewWillAppear(animated)
    }
    
    func desman_viewDidAppear(animated: Bool) {
        if EventManager.sharedInstance.swizzles.contains(Swizzle.ViewDidAppear) {
            let event = Event(type: Controller.ViewDidAppear, payload: ["controller": self.description])
            EventManager.sharedInstance.log(event)
        }        
        self.desman_viewDidAppear(animated)
    }
}