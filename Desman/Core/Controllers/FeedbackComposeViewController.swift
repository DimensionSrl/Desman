//
//  FeedbackComposeViewController.swift
//  Desman
//
//  Created by Matteo Gavagnin on 30/10/15.
//  Copyright © 2015 DIMENSION S.r.l. All rights reserved.
//

import UIKit
import Social

open class FeedbackComposeViewController: SLComposeServiceViewController {
    open var inputItems = [AnyObject]()
    let event = Event(Feedback.User)
    
    override open func didSelectPost() {
        self.dismiss(animated: true, completion: nil)
        self.event.payload = ["text": textView.text as NSCoding]
        EventManager.sharedInstance.log(event)
    }
    
    override open func didSelectCancel() {
        self.dismiss(animated: true, completion: nil)
    }
    
    open override func loadPreviewView() -> UIView! {
        if let image = event.image {
            return UIImageView(image: image)
        }
        return nil
    }
}
