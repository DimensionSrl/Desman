//
//  UIViewController-Swizzle.swift
//  Desman iOS Sample
//
//  Created by Matteo Gavagnin on 19/10/15.
//  Copyright © 2015 DIMENSION S.r.l. All rights reserved.
//

import UIKit

extension UIViewController {
    open override class func initialize() {
        struct Static {
            static var token: Int = 0
        }
        
        // make sure this isn't a subclass
        if self !== UIViewController.self {
            return
        }
        
        let justAOneTimeThing: () = {
            var originalSelector = #selector(UIViewController.viewWillAppear(_:))
            var swizzledSelector = #selector(UIViewController.desman_viewWillAppear(_:))
            
            var originalMethod = class_getInstanceMethod(self, originalSelector)
            var swizzledMethod = class_getInstanceMethod(self, swizzledSelector)
            
            let didAddMethodWill = class_addMethod(self, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod))
            
            if didAddMethodWill {
                class_replaceMethod(self, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod))
            } else {
                method_exchangeImplementations(originalMethod, swizzledMethod);
            }
            
            originalSelector = #selector(UIViewController.viewDidAppear(_:))
            swizzledSelector = #selector(UIViewController.desman_viewDidAppear(_:))
            
            originalMethod = class_getInstanceMethod(self, originalSelector)
            swizzledMethod = class_getInstanceMethod(self, swizzledSelector)
            
            let didAddMethodDid = class_addMethod(self, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod))
            
            if didAddMethodDid {
                class_replaceMethod(self, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod))
            } else {
                method_exchangeImplementations(originalMethod, swizzledMethod);
            }
            
            originalSelector = #selector(UIViewController.viewWillDisappear(_:))
            swizzledSelector = #selector(UIViewController.desman_viewWillDisappear(_:))
            
            originalMethod = class_getInstanceMethod(self, originalSelector)
            swizzledMethod = class_getInstanceMethod(self, swizzledSelector)
            
            let willDisappearAddMethodDid = class_addMethod(self, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod))
            
            if willDisappearAddMethodDid {
                class_replaceMethod(self, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod))
            } else {
                method_exchangeImplementations(originalMethod, swizzledMethod);
            }
        }()
    }
    
    // MARK: - Method Swizzling
    
    func desman_viewWillAppear(_ animated: Bool) {
        if !isDesmanController && log {
            if EventManager.sharedInstance.swizzles.contains(Swizzle.viewWillAppear) {
                let event = Event(type: Controller.ViewWillAppear, payload: ["controller": name as NSCoding])
                EventManager.sharedInstance.log(event)
            }
        }
        self.desman_viewWillAppear(animated)
    }
    
    func desman_viewDidAppear(_ animated: Bool) {
        if !isDesmanController && log {
            if EventManager.sharedInstance.swizzles.contains(Swizzle.viewDidAppear) {
                let event = Event(type: Controller.ViewDidAppear, payload: ["controller": name as NSCoding])
                EventManager.sharedInstance.log(event)
            }
        }
        self.desman_viewDidAppear(animated)
    }
    
    func desman_viewWillDisappear(_ animated: Bool) {
        if !isDesmanController && log {
            if EventManager.sharedInstance.swizzles.contains(Swizzle.viewWillDisappear) {
                let event = Event(type: Controller.ViewWillDisappear, payload: ["controller": name as NSCoding])
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
        let className = NSStringFromClass(type(of: self))
        let dotString = "."
        return "\(className.components(separatedBy: dotString).first!)"
    }
    
    var name : String {
        let className = NSStringFromClass(type(of: self))
        let dotString = "."
        return "\(className.components(separatedBy: dotString).last!)"
    }
}
