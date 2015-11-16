//
//  EventsTableViewController.swift
//  Desman iOS Sample
//
//  Created by Matteo Gavagnin on 19/10/15.
//  Copyright © 2015 DIMENSION S.r.l. All rights reserved.
//

import UIKit
import Desman

private var desmanEventsContext = 0

// Just a fake controller to be invoked and obtain the right Bundle containing Desman storyboards.
public class EventsController {

}

public class EventsTableViewController: UITableViewController, UIViewControllerPreviewingDelegate {
    var events = [Event]()
    
    public var remote : Bool = false
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        self.splitViewController?.preferredDisplayMode = .AllVisible
            
        if remote {
#if DESMAN_INCLUDES_REMOTE
            RemoteManager.sharedInstance.addObserver(self, forKeyPath: "events", options: .New, context: &desmanEventsContext)
            self.events = RemoteManager.sharedInstance.events.sort{ $0.timestamp.compare($1.timestamp) == NSComparisonResult.OrderedDescending }
#endif
        } else {
            EventManager.sharedInstance.addObserver(self, forKeyPath: "events", options: .New, context: &desmanEventsContext)
            EventManager.sharedInstance.addObserver(self, forKeyPath: "sentEvents", options: .New, context: &desmanEventsContext)
            self.events = EventManager.sharedInstance.events.sort{ $0.timestamp.compare($1.timestamp) == NSComparisonResult.OrderedDescending }
            
        }
        
        if #available(iOS 9.0, *) {
            // FIXME: should check for forceTouchCapability but for some reason it doesn't work
            registerForPreviewingWithDelegate(self, sourceView: view)
            /*
            if traitCollection.forceTouchCapability == .Available {
                registerForPreviewingWithDelegate(self, sourceView: view)
            }
            */
        }
    }

    @available(iOS 9.0, *)
    public func previewingContext(previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        guard let indexPath = tableView.indexPathForRowAtPoint(location) else { return nil }
        guard let cell = tableView.cellForRowAtIndexPath(indexPath) else { return nil }
        guard let detailVC = storyboard?.instantiateViewControllerWithIdentifier("EventDetailTableViewController") as? EventDetailTableViewController else { return nil }
        
        let selectedEvent = events[indexPath.row]
        detailVC.event = selectedEvent
        
        detailVC.preferredContentSize = CGSize(width: 0.0, height: 300)
        
        previewingContext.sourceRect = cell.frame
        
        return detailVC
    }
    
    public func previewingContext(previewingContext: UIViewControllerPreviewing, commitViewController viewControllerToCommit: UIViewController) {
        showViewController(viewControllerToCommit, sender: self)
    }
    
    @IBAction func dismissController(sender: UIBarButtonItem) {
        self.navigationController?.dismissViewControllerAnimated(true, completion: nil)
    }
    
    override public func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if context == &desmanEventsContext {
            if keyPath == "events" {
                if let updatedEvents = change?[NSKeyValueChangeNewKey] as? Set<Event> {
                    // We need to compare the updatedEvents with the events Array
                    // After the comparison we need to add, update and remove cells
                    let removedEvents = Set<Event>(events).subtract(updatedEvents)
                    let addedEvents = updatedEvents.subtract(events)
                    
                    var removeIndexPaths = [NSIndexPath]()
                    var index = 1
                    let eventsCount = events.count
                    for _ in removedEvents {
                        let indexPath = NSIndexPath(forRow: eventsCount - index, inSection: 0)
                        removeIndexPaths.append(indexPath)
                        index++
                    }
                    
                    var addedIndexPaths = [NSIndexPath]()
                    index = 0
                    for _ in addedEvents {
                        let indexPath = NSIndexPath(forRow: index, inSection: 0)
                        addedIndexPaths.append(indexPath)
                        index++
                    }
                    var rowAnimation : UITableViewRowAnimation = .Right
                    if events.count == 0 {
                        rowAnimation = .None
                    }
                    events = updatedEvents.sort{ $0.timestamp.compare($1.timestamp) == NSComparisonResult.OrderedDescending }
                    
                    tableView.beginUpdates()
                    tableView.deleteRowsAtIndexPaths(removeIndexPaths, withRowAnimation: .Left)
                    tableView.insertRowsAtIndexPaths(addedIndexPaths, withRowAnimation: rowAnimation)
                    tableView.endUpdates()
                }
            } else if keyPath == "sentEvents" {
                if let updatedEvents = change?[NSKeyValueChangeNewKey] as? Set<Event> {
                    var potentiallyUpdatedEventsDict = [Int : Event]()
                    for event in updatedEvents {
                        potentiallyUpdatedEventsDict[event.hash] = event
                    }
                    var updatedIndexPaths = [NSIndexPath]()
                    var index = 0
                    for event in events {
                        if let _ = potentiallyUpdatedEventsDict[event.hash] {
                            let indexPath = NSIndexPath(forRow: index, inSection: 0)
                            updatedIndexPaths.append(indexPath)
                        }
                        index++
                    }
                    
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(0.10 * Double(NSEC_PER_SEC))), dispatch_get_main_queue()) {
                        self.tableView.beginUpdates()
                        self.tableView.reloadRowsAtIndexPaths(updatedIndexPaths, withRowAnimation: .None)
                        self.tableView.endUpdates()
                    }
                }
            }
        } else {
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
        }
    }
    
    override public func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override public func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override public func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return events.count
    }
    
    override public func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let selectedEvent = events[indexPath.row]
        self.performSegueWithIdentifier("showEventDetailSegue", sender: selectedEvent)
    }

    override public func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("reuseIdentifier", forIndexPath: indexPath) as! EventTableViewCell
        let event = events[indexPath.row]
        cell.eventTitleLabel?.text = event.title
        if event.sent {
            cell.accessoryType = .Checkmark
        } else {
            cell.accessoryType = .None
        }
        cell.eventImageView?.image = event.image
        cell.eventSubtitleLabel?.text =
            event.dateFormatter.stringFromDate(event.timestamp)
        
        return cell
    }

    deinit {
        if remote {
#if DESMAN_INCLUDES_REMOTE
            RemoteManager.sharedInstance.removeObserver(self, forKeyPath: "events", context: &desmanEventsContext)
#endif
        } else {
            EventManager.sharedInstance.removeObserver(self, forKeyPath: "events", context: &desmanEventsContext)
            EventManager.sharedInstance.removeObserver(self, forKeyPath: "sentEvents", context: &desmanEventsContext)
        }
    }
    
    override public func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showEventDetailSegue" {
            if let detailNavigationController = segue.destinationViewController as? UINavigationController, detailController = detailNavigationController.viewControllers[0] as? EventDetailTableViewController {
                if let event = sender as? Event {
                    detailController.event = event
                }
            }
        }
    }
    
    @IBAction func infoButtonPressed(sender: UIBarButtonItem) {
        let alertController = UIAlertController(title: NSLocalizedString("Desman \(DesmanVersionNumber)", comment: ""), message: "\n\(currentUserIdentifier)\n\(currentDeviceName)", preferredStyle: .ActionSheet)
        alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .Cancel, handler: { (action) -> Void in
            alertController.dismissViewControllerAnimated(true, completion: nil)
        }))
        
        alertController.popoverPresentationController?.barButtonItem = sender
        self.presentViewController(alertController, animated: true, completion: nil)
    }
}
