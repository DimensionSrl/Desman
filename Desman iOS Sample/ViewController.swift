//
//  ViewController.swift
//  Desman iOS Sample
//
//  Created by Matteo Gavagnin on 19/10/15.
//  Copyright © 2015 DIMENSION S.r.l. All rights reserved.
//

import UIKit
import Desman

private var desmanEventsContext = 0

class ViewController: UIViewController {
    var objectToObserve = EventManager.sharedInstance
    
    override func viewDidLoad() {
        super.viewDidLoad()
        objectToObserve.addObserver(self, forKeyPath: "addedEvents", options: .New, context: &desmanEventsContext)
        objectToObserve.addObserver(self, forKeyPath: "removedEvents", options: .New, context: &desmanEventsContext)
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if context == &desmanEventsContext {
            if keyPath == "addedEvents" {
                if let newValue = change?[NSKeyValueChangeNewKey] {
                    print("Events added: \(newValue)")
                }
            } else if keyPath == "removedEvents" {
                if let newValue = change?[NSKeyValueChangeNewKey] {
                    print("Events removed: \(newValue)")
                }
            }
        } else {
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    deinit {
        objectToObserve.removeObserver(self, forKeyPath: "addedEvents", context: &desmanEventsContext)
        objectToObserve.removeObserver(self, forKeyPath: "removedEvents", context: &desmanEventsContext)
    }
}

