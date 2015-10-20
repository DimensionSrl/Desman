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

class EventsTableViewController: UITableViewController {
    var objectToObserve = EventManager.sharedInstance
    var events = [Event]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        objectToObserve.addObserver(self, forKeyPath: "addedEvents", options: .New, context: &desmanEventsContext)
        objectToObserve.addObserver(self, forKeyPath: "removedEvents", options: .New, context: &desmanEventsContext)
    }
    
    // TODO: reverse table order: newest at the top
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if context == &desmanEventsContext {
            if keyPath == "addedEvents" {
                if let newEvents = change?[NSKeyValueChangeNewKey] as? [Event] {
                    tableView.beginUpdates()
                    var indexPaths = [NSIndexPath]()
                    var index = 0
                    let eventsCount = self.events.count
                    for event in newEvents {
                        let indexPath = NSIndexPath(forRow: eventsCount + index, inSection: 0)
                        indexPaths.append(indexPath)
                        index++
                        self.events.append(event)
                    }
                    tableView.insertRowsAtIndexPaths(indexPaths, withRowAnimation: .Bottom)
                    tableView.endUpdates()
                }
            } else if keyPath == "removedEvents" {
                if let removedEvents = change?[NSKeyValueChangeNewKey] as? [Event] {
                    tableView.beginUpdates()
                    var indexPaths = [NSIndexPath]()
                    var index = 0
                    for _ in removedEvents {
                        let indexPath = NSIndexPath(forRow: index, inSection: 0)
                        indexPaths.append(indexPath)
                        index++
                        self.events.removeFirst()
                    }
                    tableView.deleteRowsAtIndexPaths(indexPaths, withRowAnimation: .Top)
                    tableView.endUpdates()
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

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return events.count
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let event = Event(type: "Select Row")
        EventManager.sharedInstance.logEvent(event)
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("reuseIdentifier", forIndexPath: indexPath)
        let event = events[indexPath.row]
        cell.textLabel?.text = event.type
        cell.detailTextLabel?.text = event.identifier
        
        return cell
    }

    deinit {
        objectToObserve.removeObserver(self, forKeyPath: "addedEvents", context: &desmanEventsContext)
        objectToObserve.removeObserver(self, forKeyPath: "removedEvents", context: &desmanEventsContext)
    }

}
