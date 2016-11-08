//
//  ImageViewController.swift
//  Desman
//
//  Created by Matteo Gavagnin on 10/11/15.
//  Copyright © 2015 DIMENSION S.r.l. All rights reserved.
//

import UIKit

open class ImageViewController: UIViewController {
    open var imageUrl : URL?
    @IBOutlet open var imageView: UIImageView!
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        if let imageUrl = imageUrl {
            imageView.loadFromURL(imageUrl)
        }
    }
    @IBAction func imageViewTapped(_ sender: UITapGestureRecognizer) {
        let hide = !navigationController!.isNavigationBarHidden
        navigationController!.setNavigationBarHidden(hide, animated: true)
    }
}
