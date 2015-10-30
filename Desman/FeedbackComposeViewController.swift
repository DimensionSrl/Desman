//
//  FeedbackComposeViewController.swift
//  Desman
//
//  Created by Matteo Gavagnin on 30/10/15.
//  Copyright © 2015 DIMENSION S.r.l. All rights reserved.
//

import UIKit
import Social

public class FeedbackComposeViewController: SLComposeServiceViewController {
    override public func didSelectPost() {
        self.dismissViewControllerAnimated(true, completion: nil)
        let event = Event(type: Type(subtype: "Feedback"), payload: ["text": textView.text])
        EventManager.sharedInstance.log(event)
    }
    
    override public func didSelectCancel() {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
}
