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
        objectToObserve.addObserver(self, forKeyPath: "events", options: .New, context: &desmanEventsContext)
        objectToObserve.addObserver(self, forKeyPath: "sentEvents", options: .New, context: &desmanEventsContext)
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
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
                    
                    events = updatedEvents.sort{ $0.timestamp.compare($1.timestamp) == NSComparisonResult.OrderedDescending }
                    
                    tableView.beginUpdates()
                    tableView.deleteRowsAtIndexPaths(removeIndexPaths, withRowAnimation: .Left)
                    tableView.insertRowsAtIndexPaths(addedIndexPaths, withRowAnimation: .Right)
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
                    
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(0.3 * Double(NSEC_PER_SEC))), dispatch_get_main_queue()) {
                        self.tableView.beginUpdates()
                        self.tableView.reloadRowsAtIndexPaths(updatedIndexPaths, withRowAnimation: .Fade)
                        self.tableView.endUpdates()
                    }
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
        let event = Event(type: Table.DidSelectRow, payload: ["row": indexPath.row, "section": indexPath.section])
        EventManager.sharedInstance.log(event)
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("reuseIdentifier", forIndexPath: indexPath)
        let event = events[indexPath.row]
        if event.sent {
            cell.textLabel?.text = "\(event.type.description) - sent"
        } else {
            cell.textLabel?.text = event.type.description
        }
        cell.imageView?.image = event.image
        
        cell.detailTextLabel?.text = event.identifier
        
        return cell
    }

    deinit {
        objectToObserve.removeObserver(self, forKeyPath: "events", context: &desmanEventsContext)
        objectToObserve.removeObserver(self, forKeyPath: "sentEvents", context: &desmanEventsContext)
    }
}
