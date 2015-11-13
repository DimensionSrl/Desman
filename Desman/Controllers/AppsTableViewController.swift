//
//  AppsTableViewController.swift
//  Desman
//
//  Created by Matteo Gavagnin on 31/10/15.
//  Copyright © 2015 DIMENSION S.r.l. All rights reserved.
//

import UIKit

private var desmanAppsContext = 0

class AppsTableViewController: UITableViewController {
    var objectToObserve = RemoteManager.sharedInstance
    var apps = [App]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.splitViewController?.preferredDisplayMode = .AllVisible
        
        objectToObserve.addObserver(self, forKeyPath: "apps", options: .New, context: &desmanAppsContext)
        
        self.apps = Array(RemoteManager.sharedInstance.apps)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        RemoteManager.sharedInstance.fetchApps()
    }
    
    func previewingContext(previewingContext: UIViewControllerPreviewing, commitViewController viewControllerToCommit: UIViewController) {
        showViewController(viewControllerToCommit, sender: self)
    }
    
    @IBAction func dismissController(sender: UIBarButtonItem) {
        self.navigationController?.dismissViewControllerAnimated(true, completion: nil)
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if context == &desmanAppsContext {
            if keyPath == "apps" {
                if let updatedApps = change?[NSKeyValueChangeNewKey] as? Set<App> {
                    // We need to compare the updatedEvents with the events Array
                    // After the comparison we need to add, update and remove cells
                    let removedApps = Set<App>(apps).subtract(updatedApps)
                    let addedApps = updatedApps.subtract(apps)
                    
                    var removeIndexPaths = [NSIndexPath]()
                    var index = 1
                    let appsCount = apps.count
                    for _ in removedApps {
                        let indexPath = NSIndexPath(forRow: appsCount - index, inSection: 0)
                        removeIndexPaths.append(indexPath)
                        index++
                    }
                    
                    var addedIndexPaths = [NSIndexPath]()
                    index = 0
                    for _ in addedApps {
                        let indexPath = NSIndexPath(forRow: index, inSection: 0)
                        addedIndexPaths.append(indexPath)
                        index++
                    }
                    var rowAnimation : UITableViewRowAnimation = .Right
                    if apps.count == 0 {
                        rowAnimation = .None
                    }
                    apps = Array(updatedApps)
                    
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
        return apps.count
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let selectedApp = apps[indexPath.row]
        RemoteManager.sharedInstance.fetchUsers(selectedApp)
        self.performSegueWithIdentifier("showUsersSegue", sender: selectedApp)
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("appCell", forIndexPath: indexPath) as! AppTableViewCell
        let app = apps[indexPath.row]
        cell.appTitleLabel.text = app.title
        cell.appImageView.isIcon()
        if let iconUrl = app.iconUrl {
            cell.appImageView.loadFromURL(iconUrl)
        }
        return cell
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showUsersSegue" {
            if let detailController = segue.destinationViewController as? UsersTableViewController {
                if let sender = sender as? App {
                    detailController.app = sender
                }
            }
        }
    }
    
    deinit {
        objectToObserve.removeObserver(self, forKeyPath: "apps", context: &desmanAppsContext)
    }
}

extension UIImageView {
    // Loads image asynchronously
    func loadFromURL(url: NSURL) {
        ImageCache.sharedInstance.getImage(url) { (image, error) -> () in
            if let image = image {
                if image.size.height < self.bounds.size.height / self.contentScaleFactor && image.size.width < self.bounds.size.width / self.contentScaleFactor {
                    self.contentMode = .Center
                }
                self.image = image
            }
        }
    }
    
    func isIcon() {
        self.image = UIImage(named: "Icon Placeholder", inBundle: NSBundle(forClass: EventManager.self), compatibleWithTraitCollection: nil)
        self.layer.cornerRadius = self.frame.size.height / 5
        self.clipsToBounds = true
    }
    
    func isUser() {
        self.image = UIImage(named: "User Placeholder", inBundle: NSBundle(forClass: EventManager.self), compatibleWithTraitCollection: nil)
        self.layer.cornerRadius = self.frame.size.height / 2
        self.clipsToBounds = true
    }

}
