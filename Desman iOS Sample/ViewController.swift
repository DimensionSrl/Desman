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

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func showEvents(sender: UIBarButtonItem) {
        let desmanStoryboard = UIStoryboard(name: "Desman", bundle: NSBundle(forClass: EventManager.self))
        let desmanController = desmanStoryboard.instantiateViewControllerWithIdentifier("eventsController")
        self.presentViewController(desmanController, animated: true, completion: nil)
    }
    
    @IBAction func feedbackCompose(sender: UIButton) {
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
