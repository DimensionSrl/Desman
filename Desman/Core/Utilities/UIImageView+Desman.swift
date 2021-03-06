//
//  UIImageView+Desman.swift
//  Desman
//
//  Created by Matteo Gavagnin on 13/11/15.
//  Copyright © 2015 DIMENSION S.r.l. All rights reserved.
//

import UIKit

public extension UIImageView {
    // Loads image asynchronously
    func loadFromURL(_ url: URL) {
        ImageCache.sharedInstance.getImage(url) { (image, error) -> () in
            if let image = image {
                if image.size.height < self.bounds.size.height / self.contentScaleFactor && image.size.width < self.bounds.size.width / self.contentScaleFactor {
                    self.contentMode = .center
                }
                self.image = image
            }
        }
    }
    
    public func isIcon() {
        self.image = UIImage(named: "Icon Placeholder", in: Bundle(for: EventsTableViewController.self), compatibleWith: nil)
        self.layer.cornerRadius = self.frame.size.height / 5
        self.clipsToBounds = true
    }
    
    public func isUser() {
        self.image = UIImage(named: "User Placeholder", in: Bundle(for: EventsTableViewController.self), compatibleWith: nil)
        self.layer.cornerRadius = self.frame.size.height / 2
        self.clipsToBounds = true
    }
}
