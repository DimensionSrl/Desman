//
//  EventsTableViewController.swift
//  Desman iOS Sample
//
//  Created by Matteo Gavagnin on 19/10/15.
//  Copyright © 2015 DIMENSION S.r.l. All rights reserved.
//

import UIKit

private var desmanEventsContext = 0

// Just a fake controller to be invoked and obtain the right Bundle containing Desman storyboards.
open class EventsController {

}

open class EventsTableViewController: UITableViewController, UIViewControllerPreviewingDelegate {
    var events = [Event]()
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        self.splitViewController?.preferredDisplayMode = .allVisible
        
        EventManager.shared.addObserver(self, forKeyPath: "events", options: .new, context: &desmanEventsContext)
        EventManager.shared.addObserver(self, forKeyPath: "sentEvents", options: .new, context: &desmanEventsContext)
        self.events = EventManager.shared.events.sorted{ $0.timestamp.compare($1.timestamp as Date) == ComparisonResult.orderedDescending }
        
        if #available(iOS 9.0, *) {
            // FIXME: should check for forceTouchCapability but for some reason it doesn't work
            registerForPreviewing(with: self, sourceView: view)
            /*
            if traitCollection.forceTouchCapability == .Available {
                registerForPreviewingWithDelegate(self, sourceView: view)
            }
            */
        }
    }

    @available(iOS 9.0, *)
    open func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        guard let indexPath = tableView.indexPathForRow(at: location) else { return nil }
        guard let cell = tableView.cellForRow(at: indexPath) else { return nil }
        guard let detailVC = storyboard?.instantiateViewController(withIdentifier: "EventDetailTableViewController") as? EventDetailTableViewController else { return nil }
        
        let selectedEvent = events[(indexPath as NSIndexPath).row]
        detailVC.event = selectedEvent
        
        detailVC.preferredContentSize = CGSize(width: 0.0, height: 300)
        
        previewingContext.sourceRect = cell.frame
        
        return detailVC
    }
    
    open func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        show(viewControllerToCommit, sender: self)
    }
    
    @IBAction func dismissController(_ sender: UIBarButtonItem) {
        self.navigationController?.dismiss(animated: true, completion: nil)
    }
    
    override open func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if context == &desmanEventsContext {
            if keyPath == "events" {
                if let updatedEvents = change?[NSKeyValueChangeKey.newKey] as? [Event] {
                    // We need to compare the updatedEvents with the events Array
                    // After the comparison we need to add, update and remove cells
                    let removedEvents = events.removeObjectsInArray(updatedEvents)
                    let addedEvents = updatedEvents.removeObjectsInArray(events)
                    
                    var removeIndexPaths = [IndexPath]()
                    var index = 1
                    let eventsCount = events.count
                    for _ in removedEvents {
                        let indexPath = IndexPath(row: eventsCount - index, section: 0)
                        removeIndexPaths.append(indexPath)
                        index += 1
                    }
                    
                    var addedIndexPaths = [IndexPath]()
                    index = 0
                    for _ in addedEvents {
                        let indexPath = IndexPath(row: index, section: 0)
                        addedIndexPaths.append(indexPath)
                        index += 1
                    }
                    var rowAnimation : UITableViewRowAnimation = .right
                    if events.count == 0 {
                        rowAnimation = .none
                    }
                    events = updatedEvents.sorted{ $0.timestamp.compare($1.timestamp) == ComparisonResult.orderedDescending }
                    
                    tableView.beginUpdates()
                    tableView.deleteRows(at: removeIndexPaths, with: .left)
                    tableView.insertRows(at: addedIndexPaths, with: rowAnimation)
                    tableView.endUpdates()
                }
            } else if keyPath == "sentEvents" {
                if let updatedEvents = change?[NSKeyValueChangeKey.newKey] as? [Event] {
                    var potentiallyUpdatedEventsDict = [Int : Event]()
                    for event in updatedEvents {
                        potentiallyUpdatedEventsDict[event.hash] = event
                    }
                    var updatedIndexPaths = [IndexPath]()
                    var index = 0
                    for event in events {
                        if let _ = potentiallyUpdatedEventsDict[event.hash] {
                            let indexPath = IndexPath(row: index, section: 0)
                            updatedIndexPaths.append(indexPath)
                        }
                        index += 1
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(0.10 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)) {
                        self.tableView.beginUpdates()
                        self.tableView.reloadRows(at: updatedIndexPaths, with: .none)
                        self.tableView.endUpdates()
                    }
                }
            }
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
    
    override open func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override open func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return events.count
    }
    
    override open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedEvent = events[(indexPath as NSIndexPath).row]
        self.performSegue(withIdentifier: "showEventDetailSegue", sender: selectedEvent)
    }

    override open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath) as! EventTableViewCell
        let event = events[(indexPath as NSIndexPath).row]
        cell.eventTitleLabel?.text = event.title
        if event.sent {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }
        cell.eventImageView?.image = event.image
        cell.eventSubtitleLabel?.text = event.dateFormatter.string(from: event.timestamp)
        
        return cell
    }

    deinit {
        EventManager.shared.removeObserver(self, forKeyPath: "events", context: &desmanEventsContext)
        EventManager.shared.removeObserver(self, forKeyPath: "sentEvents", context: &desmanEventsContext)
    }
    
    override open func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showEventDetailSegue" {
            if let detailNavigationController = segue.destination as? UINavigationController, let detailController = detailNavigationController.viewControllers[0] as? EventDetailTableViewController {
                if let event = sender as? Event {
                    detailController.event = event
                }
            }
        }
    }
    
    @IBAction func infoButtonPressed(_ sender: UIBarButtonItem) {
        let alertController = UIAlertController(title: NSLocalizedString("Desman \(DesmanVersionNumber)", comment: ""), message: "\n\(currentUserIdentifier)\n\(currentDeviceName)", preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .cancel, handler: { (action) -> Void in
            alertController.dismiss(animated: true, completion: nil)
        }))
        
        alertController.popoverPresentationController?.barButtonItem = sender
        self.present(alertController, animated: true, completion: nil)
    }
}
