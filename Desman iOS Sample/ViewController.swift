//
//  ViewController.swift
//  Desman
//
//  Created by Matteo Gavagnin on 28/10/15.
//  Copyright © 2015 DIMENSION S.r.l. All rights reserved.
//

import UIKit
import Desman

private var desmanRemoteContext = 0

class ViewController: UIViewController {
    var objectToObserve = RemoteManager.sharedInstance
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        objectToObserve.addObserver(self, forKeyPath: "apps", options: .New, context: &desmanRemoteContext)
        objectToObserve.addObserver(self, forKeyPath: "users", options: .New, context: &desmanRemoteContext)
        objectToObserve.addObserver(self, forKeyPath: "events", options: .New, context: &desmanRemoteContext)
        
        // RemoteManager.sharedInstance.fetchApps()
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if context == &desmanRemoteContext {
            if keyPath == "apps" {
                if let updatedApps = change?[NSKeyValueChangeNewKey] as? Set<App> {
                    print(updatedApps)
                    if let app = updatedApps.first {
                        RemoteManager.sharedInstance.fetchUsers(app)
                    }
                }
            } else if keyPath == "users" {
                if let updatedUsers = change?[NSKeyValueChangeNewKey] as? Set<User> {
                    print(updatedUsers)
                    if let user = updatedUsers.first {
                        RemoteManager.sharedInstance.fetchEvents(user)
                    }
                }
            } else if keyPath == "events" {
                if let updatedEvents = change?[NSKeyValueChangeNewKey] as? Set<Event> {
                    print(updatedEvents)
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

    @IBAction func showEvents(sender: UIBarButtonItem) {
        D.log(Action.Button, payload: ["button": "show events"])
        let desmanStoryboard = UIStoryboard(name: "Desman", bundle: NSBundle(forClass: EventManager.self))
        let desmanController = desmanStoryboard.instantiateViewControllerWithIdentifier("eventsController")
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
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
