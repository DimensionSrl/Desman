//
//  ImageViewController.swift
//  Desman
//
//  Created by Matteo Gavagnin on 10/11/15.
//  Copyright © 2015 DIMENSION S.r.l. All rights reserved.
//

import UIKit

class ImageViewController: UIViewController {
    var imageUrl : NSURL?
    @IBOutlet var imageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let imageUrl = imageUrl {
            imageView.loadFromURL(imageUrl)
        }
    }
    @IBAction func imageViewTapped(sender: UITapGestureRecognizer) {
        navigationController!.setNavigationBarHidden(!navigationController!.navigationBarHidden, animated: true)
    }
}
