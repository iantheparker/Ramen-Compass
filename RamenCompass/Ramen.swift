//
//  Ramen.swift
//  Ramen Compass
//
//  Created by Ian Parker on 2/20/15.
//  Copyright (c) 2015 Tumbleweed. All rights reserved.
//

import Foundation
import RealmSwift

class Location: Object {
    dynamic var lat = 0.0  // latitude
    dynamic var lng = 0.0  // longitude
    dynamic var distance = 0.0
    dynamic var address = ""
    dynamic var postalCode = ""
    dynamic var cc = ""
    dynamic var city = ""
    dynamic var state = ""
    dynamic var country = ""
    
}

class Venue: Object {
    dynamic var id = ""
    dynamic var name = ""
    dynamic var location = Location()
    
    dynamic var hours = ""
    dynamic var tips = ""
    
    dynamic var photoUrl = ""
    dynamic var photoData : NSData = NSData()
    
    override static func primaryKey() -> String? {
        return "id"
    }
}
