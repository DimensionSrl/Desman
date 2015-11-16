//
//  ImageViewController.swift
//  Desman
//
//  Created by Matteo Gavagnin on 10/11/15.
//  Copyright © 2015 DIMENSION S.r.l. All rights reserved.
//

import UIKit

public class ImageViewController: UIViewController {
    public var imageUrl : NSURL?
    @IBOutlet public var imageView: UIImageView!
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        if let imageUrl = imageUrl {
            imageView.loadFromURL(imageUrl)
        }
    }
    @IBAction func imageViewTapped(sender: UITapGestureRecognizer) {
        let hide = !navigationController!.navigationBarHidden
        UIApplication.sharedApplication().setStatusBarHidden(hide, withAnimation: .Slide)
        navigationController!.setNavigationBarHidden(hide, animated: true)
    }
}