//
//  EventDetailTableViewController.swift
//  Desman
//
//  Created by Matteo Gavagnin on 28/10/15.
//  Copyright © 2015 DIMENSION S.r.l. All rights reserved.
//

import UIKit
import MapKit

public class EventDetailTableViewController: UITableViewController, MKMapViewDelegate {
    public var event : Event?
    @IBOutlet weak var uuidLabel: UILabel!
    @IBOutlet weak var typeLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var payloadTextView: UITextView!
    @IBOutlet var sentCell: UITableViewCell!
    @IBOutlet var mapView: MKMapView!
    @IBOutlet var payloadTrailingConstraint: NSLayoutConstraint!
    @IBOutlet var payloadLeadingConstraint: NSLayoutConstraint!
    
    @IBOutlet var attachmentImageView: UIImageView!
    
    var region : CLCircularRegion?
    var location : CLLocationCoordinate2D?
    var regionState : String?
    
    @IBAction func attachmentTapped(sender: UITapGestureRecognizer) {
        performSegueWithIdentifier("showImageAttachmentSegue", sender: self)
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Event Details"
        self.tableView.rowHeight = UITableViewAutomaticDimension;
        self.tableView.estimatedRowHeight = 44.0;
    }

    override public func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if let event = event {
            typeLabel.text = event.title
            uuidLabel.text = event.uuid?.UUIDString
            dateLabel.text = event.dateFormatter.stringFromDate(event.timestamp)
            
            if event.sent {
                sentCell.accessoryType = .Checkmark
            } else {
                sentCell.accessoryType = .None
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
                        let replacedString = string.stringByReplacingOccurrencesOfString("\\/", withString: "/")
                        payloadTextView.text = replacedString
                    }
                } catch _ as NSError {
                    payloadTextView.text = NSLocalizedString("Error: cannot parse the Event Payload.", comment: "")
                }
                
                // TODO: extension to support geofences
                if let region = payload["region"] as? [String: AnyObject], lat = region["lat"] as? Double, lon = region["lon"] as? Double, radius = region["radius"] as? CLLocationDistance, state = region["state"] as? String {
                    self.region = CLCircularRegion(center: CLLocationCoordinate2DMake(lat, lon), radius: radius, identifier: "region")
                    self.regionState = state
                    
                    let location = CLLocation(latitude: lat, longitude: lon)
                    let circle = MKCircle(centerCoordinate: location.coordinate, radius: radius)
                    self.mapView.addOverlay(circle)
                }
                
                if let location = payload["location"] as? [String: AnyObject], lat = location["lat"] as? Double, lon = location["lon"] as? Double {
                    self.location = CLLocationCoordinate2DMake(lat, lon)
                    let location = CLLocation(latitude: lat, longitude: lon)
                    let circle = MKCircle(centerCoordinate: location.coordinate, radius: 5)
                    self.mapView.addOverlay(circle)
                }
                
                self.zoomToFitOverlays(self.mapView.overlays, animated: true, offsetProportion: 0.1)
            } else {
                payloadTextView.text = ""
            }
            
            if let attachmentUrl = event.attachmentUrl {
                attachmentImageView.userInteractionEnabled = true
                attachmentImageView.loadFromURL(attachmentUrl)
            } else if let attachment = event.attachment, let image = UIImage(data: attachment) {
                attachmentImageView.userInteractionEnabled = true
                attachmentImageView.image = image
            } else {
                attachmentImageView.userInteractionEnabled = false
            }
        }
    }
    
    // MARK: - Table view data source

    override public func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.row == 6 {
            if payloadTextView.text.lengthOfBytesUsingEncoding(NSUTF8StringEncoding) == 0 {
                return 44
            }
            let size = payloadTextView.sizeThatFits(CGSize(width: self.view.frame.size.width - payloadLeadingConstraint.constant - payloadTrailingConstraint.constant, height: CGFloat.max))
            return size.height + 1
        } else if indexPath.row == 4 {
            if (event?.attachmentUrl != nil) || (event?.attachment != nil) {
                return tableView.frame.size.width / 3.0
            } else {
                return 0
            }
        } else if indexPath.row == 5 {
            if region != nil || location != nil {
                return 200
            } else {
                return 0
            }
        }
        
        return 44
    }
    
    override public func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let event = event {
            if segue.identifier == "showImageAttachmentSegue" {
                if let destination = segue.destinationViewController as? ImageViewController {
                    if let attachmentUrl = event.attachmentUrl {
                        destination.imageUrl = attachmentUrl
                    } else if let attachment = event.attachment, let image = UIImage(data: attachment) {
                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(0.10 * Double(NSEC_PER_SEC))), dispatch_get_main_queue()) {
                            destination.imageView.image = image
                        }
                    }
                    destination.title = event.title
                }
            }
        }
    }
    
    public func mapView(mapView: MKMapView, rendererForOverlay overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is MKCircle {
            let circle = MKCircleRenderer(overlay: overlay)
            circle.strokeColor = UIColor.blueColor()
            circle.fillColor = UIColor(red: 0, green: 0, blue: 255, alpha: 0.1)
            circle.lineDashPattern = [4, 2]
            circle.fillColor = UIColor(red: 0, green: 0, blue: 255, alpha: 0.1)
            circle.lineWidth = 0.5
            return circle
        } else {
            return MKCircleRenderer(overlay: overlay)
        }
    }
    
    func zoomToFitOverlays(overlays: [MKOverlay], animated:Bool, offsetProportion:Double) {
        if overlays.count == 0 {
            return
        }
        
        var mapRect = MKMapRectNull
        if overlays.count == 1 {
            mapRect = overlays.last!.boundingMapRect
        } else {
            for overlay in overlays {
                mapRect = MKMapRectUnion(mapRect, overlay.boundingMapRect)
            }
        }
        
        var proportion = offsetProportion
        if offsetProportion > 1 {
            proportion = 0.9
        }
        
        let offset = mapRect.size.width * proportion
        mapRect = mapView.mapRectThatFits(MKMapRectInset(mapRect, -offset, -offset))
        let region = MKCoordinateRegionForMapRect(mapRect)
        mapView.setRegion(region, animated: true)
    }

}
