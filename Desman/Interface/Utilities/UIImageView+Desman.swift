//
//  UIImageView+Desman.swift
//  Desman
//
//  Created by Matteo Gavagnin on 13/11/15.
//  Copyright © 2015 DIMENSION S.r.l. All rights reserved.
//

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