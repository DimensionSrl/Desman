//
//  ViewController.swift
//  Desman
//
//  Created by Matteo Gavagnin on 28/10/15.
//  Copyright © 2015 DIMENSION S.r.l. All rights reserved.
//

import UIKit
import Desman

class ViewController: UIViewController {
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        
        D.logType(Warning(subtype: "memory"))
    }

    @IBAction func showEvents(sender: UIBarButtonItem) {
        D.log(Action.Button, payload: ["button": "show events"])
        let desmanStoryboard = UIStoryboard(name: "Desman", bundle: NSBundle(forClass: EventsController.self))
        let desmanController = desmanStoryboard.instantiateViewControllerWithIdentifier("eventsController")
        self.presentViewController(desmanController, animated: true, completion: nil)
    }
    
    @IBAction func showRemote(sender: UIButton) {
        D.log(Action.Button, payload: ["button": "show remote"])
        let desmanStoryboard = UIStoryboard(name: "Remote", bundle: NSBundle(forClass: RemoteController.self))
        let desmanController = desmanStoryboard.instantiateViewControllerWithIdentifier("remoteController")
        self.presentViewController(desmanController, animated: true, completion: nil)
    }
    
    @IBAction func feedbackCompose(sender: UIButton) {
        D.log(Action.Button, payload: ["button": "feedback compose"])
        let feedbackController = FeedbackComposeViewController()
        feedbackController.placeholder = "Give your feedback"
        feedbackController.modalPresentationStyle = .OverCurrentContext
        self.presentViewController(feedbackController, animated: true) { () -> Void in
        }
    }
    
    @IBAction func takeScreenshot(sender: UIButton) {
        UIGraphicsBeginImageContextWithOptions(self.view.bounds.size, false, UIScreen.mainScreen().scale)
        self.view.drawViewHierarchyInRect(self.view.bounds, afterScreenUpdates: true)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        if let compressedImage = UIImageJPEGRepresentation(image, 0.4) {
            let event = Event(type: Controller.Screenshot, payload: ["controller": "View Controller"], attachment: compressedImage)
            D.log(event)
        }
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
