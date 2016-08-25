//
//  EventDetailTableViewController.swift
//  Desman
//
//  Created by Matteo Gavagnin on 28/10/15.
//  Copyright © 2015 DIMENSION S.r.l. All rights reserved.
//

import UIKit
import MapKit

open class EventDetailTableViewController: UITableViewController, MKMapViewDelegate {
    open var event : Event?
    @IBOutlet weak var uuidLabel: UILabel!
    @IBOutlet weak var typeLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet var valueLabel: UILabel!
    @IBOutlet weak var payloadTextView: UITextView!
    @IBOutlet var sentCell: UITableViewCell!
    @IBOutlet var mapView: MKMapView!
    @IBOutlet var payloadTrailingConstraint: NSLayoutConstraint!
    @IBOutlet var payloadLeadingConstraint: NSLayoutConstraint!
    
    @IBOutlet var attachmentImageView: UIImageView!
    
    var region : CLCircularRegion?
    var location : CLLocationCoordinate2D?
    var regionState : String?
    
    @IBAction func attachmentTapped(_ sender: UITapGestureRecognizer) {
        performSegue(withIdentifier: "showImageAttachmentSegue", sender: self)
    }
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Event Details"
        self.tableView.rowHeight = UITableViewAutomaticDimension;
        self.tableView.estimatedRowHeight = 44.0;
    }

    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let event = event {
            typeLabel.text = event.title
            uuidLabel.text = event.uuid?.uuidString
            dateLabel.text = event.dateFormatter.string(from: event.timestamp)
            
            if let value = event.value {
                valueLabel.text = value
            } else {
                valueLabel.text = ""
            }
            
            if event.sent {
                sentCell.accessoryType = .checkmark
            } else {
                sentCell.accessoryType = .none
            }
            
            if let image = event.image {
                let imageView = UIImageView(image: image)
                imageView.frame = imageView.frame.insetBy(dx: 8, dy: 8)
                let imageButton = UIBarButtonItem(customView: imageView)
                self.navigationItem.rightBarButtonItem = imageButton
            }
            
            if let payload = event.payload {
                do {
                    let data = try JSONSerialization.data(withJSONObject: payload, options: JSONSerialization.WritingOptions.prettyPrinted)
                    if let string = String(data: data, encoding: String.Encoding.utf8) {
                        let replacedString = string.replacingOccurrences(of: "\\/", with: "/")
                        payloadTextView.text = replacedString
                    }
                } catch _ as NSError {
                    payloadTextView.text = NSLocalizedString("Error: cannot parse the Event Payload.", comment: "")
                }
                
                // TODO: extension to support geofences
                if let lat = payload["lat"] as? Double, let lon = payload["lon"] as? Double, let radius = payload["radius"] as? CLLocationDistance, let state = payload["state"] as? String {
                    self.region = CLCircularRegion(center: CLLocationCoordinate2DMake(lat, lon), radius: radius, identifier: "region")
                    self.regionState = state
                    
                    let location = CLLocation(latitude: lat, longitude: lon)
                    let circle = MKCircle(center: location.coordinate, radius: radius)
                    self.mapView.add(circle)
                }
                
                if let lat = payload["userLat"] as? Double, let lon = payload["userLon"] as? Double {
                    self.location = CLLocationCoordinate2DMake(lat, lon)
                    let location = CLLocation(latitude: lat, longitude: lon)
                    let circle = MKCircle(center: location.coordinate, radius: 5)
                    self.mapView.add(circle)
                }
                
                self.zoomToFitOverlays(self.mapView.overlays, animated: true, offsetProportion: 0.1)
            } else {
                payloadTextView.text = ""
            }
            
            if let attachmentUrl = event.attachmentUrl {
                attachmentImageView.isUserInteractionEnabled = true
                attachmentImageView.loadFromURL(attachmentUrl)
            } else if let attachment = event.attachment, let image = UIImage(data: attachment as Data) {
                attachmentImageView.isUserInteractionEnabled = true
                attachmentImageView.image = image
            } else {
                attachmentImageView.isUserInteractionEnabled = false
            }
        }
    }
    
    // MARK: - Table view data source

    override open func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if (indexPath as NSIndexPath).row == 7 {
            if payloadTextView.text.lengthOfBytes(using: String.Encoding.utf8) == 0 {
                return 44
            }
            let size = payloadTextView.sizeThatFits(CGSize(width: self.view.frame.size.width - payloadLeadingConstraint.constant - payloadTrailingConstraint.constant, height: CGFloat.greatestFiniteMagnitude))
            return size.height + 1
        } else if (indexPath as NSIndexPath).row == 5 {
            if (event?.attachmentUrl != nil) || (event?.attachment != nil) {
                return tableView.frame.size.width / 3.0
            } else {
                return 0
            }
        } else if (indexPath as NSIndexPath).row == 6 {
            if region != nil || location != nil {
                return 200
            } else {
                return 0
            }
        }
        
        return 44
    }
    
    override open func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let event = event {
            if segue.identifier == "showImageAttachmentSegue" {
                if let destination = segue.destination as? ImageViewController {
                    if let attachmentUrl = event.attachmentUrl {
                        destination.imageUrl = attachmentUrl
                    } else if let attachment = event.attachment, let image = UIImage(data: attachment as Data) {
                        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(0.10 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)) {
                            destination.imageView.image = image
                        }
                    }
                    destination.title = event.title
                }
            }
        }
    }
    
    open func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is MKCircle {
            let circle = MKCircleRenderer(overlay: overlay)
            circle.strokeColor = UIColor.blue
            circle.fillColor = UIColor(red: 0, green: 0, blue: 255, alpha: 0.1)
            circle.lineDashPattern = [4, 2]
            circle.fillColor = UIColor(red: 0, green: 0, blue: 255, alpha: 0.1)
            circle.lineWidth = 0.5
            return circle
        } else {
            return MKCircleRenderer(overlay: overlay)
        }
    }
    
    func zoomToFitOverlays(_ overlays: [MKOverlay], animated:Bool, offsetProportion:Double) {
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
