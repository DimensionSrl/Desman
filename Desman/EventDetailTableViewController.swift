//
//  EventDetailTableViewController.swift
//  Desman
//
//  Created by Matteo Gavagnin on 28/10/15.
//  Copyright © 2015 DIMENSION S.r.l. All rights reserved.
//

import UIKit

class EventDetailTableViewController: UITableViewController {
    var event : Event?
    @IBOutlet weak var uuidLabel: UILabel!
    @IBOutlet weak var typeLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var payloadTextView: UITextView!
    @IBOutlet weak var sentLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Event"
        self.tableView.rowHeight = UITableViewAutomaticDimension;
        self.tableView.estimatedRowHeight = 44.0;
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if let event = event {
            typeLabel.text = event.type.description
            uuidLabel.text = event.uuid?.UUIDString
            dateLabel.text = event.dateFormatter.stringFromDate(event.timestamp)
            if event.sent {
                sentLabel.text = "True"
            } else {
                sentLabel.text = "False"
            }
            
            if let image = event.image {
                let imageView = UIImageView(image: image)
                imageView.frame = CGRectInset(imageView.frame, 8, 8)
                let imageButton = UIBarButtonItem(customView: imageView)
                self.navigationItem.rightBarButtonItem = imageButton
            }
            
            if let payload = event.payload {
                do {
                    let data = try NSJSONSerialization.dataWithJSONObject(payload, options: NSJSONWritingOptions.PrettyPrinted)
                    if let string = String(data: data, encoding: NSUTF8StringEncoding) {
                        payloadTextView.text = string
                    }
                } catch _ as NSError {
                    payloadTextView.text = NSLocalizedString("Error: cannot parse the Event Payload.", comment: "")
                }
            } else {
                payloadTextView.text = ""
            }
        }
    }
    
    // MARK: - Table view data source

    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.row == 4 {
            let size = payloadTextView.sizeThatFits(CGSize(width: tableView.frame.size.width - 25, height: CGFloat.max))
            return size.height + 2
        }
        return 44
    }
}
