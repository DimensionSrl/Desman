//
//  SampleType.swift
//  Desman iOS Sample
//
//  Created by Matteo Gavagnin on 26/10/15.
//  Copyright © 2015 DIMENSION S.r.l. All rights reserved.
//

import Desman

class SampleType : Type {
    static let Unknown = SampleType(subtype: "Unknown")
    override var image : UIImage? {
        return UIImage(named: "Unknown")
    }
}