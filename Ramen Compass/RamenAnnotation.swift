//
//  RamenAnnotation.swift
//  Ramen Compass
//
//  Created by Ian Parker on 2/20/15.
//  Copyright (c) 2015 Tumbleweed. All rights reserved.
//

import UIKit
import MapKit

class RamenAnnotation: NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D
    var title: String
    var subtitle: String
    var venue: Venue!
    
    init(coordinate: CLLocationCoordinate2D, title: String, subtitle: String, venue : Venue? = nil) {
        self.coordinate = coordinate
        self.title = title
        self.subtitle = subtitle
        self.venue = venue
    }
}
