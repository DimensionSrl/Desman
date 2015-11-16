//
//  UsersTableViewController.swift
//  Desman
//
//  Created by Matteo Gavagnin on 31/10/15.
//  Copyright © 2015 DIMENSION S.r.l. All rights reserved.
//

import UIKit
#if !DESMAN_AS_COCOAPOD
import Desman
import DesmanInterface
#endif
private var desmanUsersContext = 0

class UsersTableViewController: UITableViewController {
    var objectToObserve = RemoteManager.sharedInstance
    var users = [User]()
    var app : App?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.splitViewController?.preferredDisplayMode = .AllVisible
        
        objectToObserve.addObserver(self, forKeyPath: "users", options: .New, context: &desmanUsersContext)
        
        self.users = Array(RemoteManager.sharedInstance.users)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
#if DESMAN_INCLUDES_REALTIME
        RemoteManager.sharedInstance.stopFetchingEvents()
#endif
    }
    
    @IBAction func dismissController(sender: UIBarButtonItem) {
        self.navigationController?.dismissViewControllerAnimated(true, completion: nil)
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if context == &desmanUsersContext {
            if keyPath == "users" {
                if let updated = change?[NSKeyValueChangeNewKey] as? Set<User> {
                    // We need to compare the updatedEvents with the events Array
                    // After the comparison we need to add, update and remove cells
                    let removed = Set<User>(users).subtract(updated)
                    let added = updated.subtract(users)
                    
                    var removeIndexPaths = [NSIndexPath]()
                    var index = 1
                    let count = users.count
                    for _ in removed {
                        let indexPath = NSIndexPath(forRow: count - index, inSection: 0)
                        removeIndexPaths.append(indexPath)
                        index++
                    }
                    
                    var addedIndexPaths = [NSIndexPath]()
                    index = 0
                    for _ in added {
                        let indexPath = NSIndexPath(forRow: index, inSection: 0)
                        addedIndexPaths.append(indexPath)
                        index++
                    }
                    var rowAnimation : UITableViewRowAnimation = .Right
                    if users.count == 0 {
                        rowAnimation = .None
                    }
                    users = Array(updated)
                    
                    tableView.beginUpdates()
                    tableView.deleteRowsAtIndexPaths(removeIndexPaths, withRowAnimation: .Left)
                    tableView.insertRowsAtIndexPaths(addedIndexPaths, withRowAnimation: rowAnimation)
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
        return users.count
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let selectedUser = users[indexPath.row]
        if let app = app {
            RemoteManager.sharedInstance.fetchEvents(app, user: selectedUser)
            self.performSegueWithIdentifier("showEventsSegue", sender: selectedUser)
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("userCell", forIndexPath: indexPath) as! UserTableViewCell
        let user = users[indexPath.row]
        cell.userTitleLabel.text = user.title
        cell.userImageView.isUser()
        if let imageUrl = user.imageUrl {
            cell.userImageView.loadFromURL(imageUrl)
        }
        return cell
    }
    
    deinit {
        objectToObserve.removeObserver(self, forKeyPath: "users", context: &desmanUsersContext)
    }
}
