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
    public var inputItems = [AnyObject]()
    let event = Event(User.Feedback)
    
    override public func didSelectPost() {
        self.dismissViewControllerAnimated(true, completion: nil)
        self.event.payload = ["text": textView.text]
        EventManager.sharedInstance.log(event)
    }
    
    override public func didSelectCancel() {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    public override func loadPreviewView() -> UIView! {
        if let image = event.image {
            return UIImageView(image: image)
        }
        return nil
    }
}
