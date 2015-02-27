//
//  Ramen.swift
//  Ramen Compass
//
//  Created by Ian Parker on 2/20/15.
//  Copyright (c) 2015 Tumbleweed. All rights reserved.
//

import Foundation
import Realm

//class Ramen: RLMObject {
//    
//    dynamic var distance = 0.0
//    dynamic var pageUrl = ""
//    
//    override class func primaryKey() -> String! {
//        return "venueId"
//    }
//    
//    func ignoredProperties() -> NSArray {
//        let propertiesToIgnore = [distance]
//        return propertiesToIgnore
//    }
//}

class Location: RLMObject {
    dynamic var lat = 0.0  // latitude
    dynamic var lng = 0.0  // longitude
    dynamic var postalCode = ""
    dynamic var cc = ""
    dynamic var state = ""
    dynamic var country = ""
    dynamic var distance = 0.0
}

class Venue: RLMObject {
    dynamic var id = ""
    dynamic var name = ""
    dynamic var location = Location()
    
    override class func primaryKey() -> String! {
        return "id"
    }
}
