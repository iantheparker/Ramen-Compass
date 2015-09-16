//
//  Ramen.swift
//  Ramen Compass
//
//  Created by Ian Parker on 2/20/15.
//  Copyright (c) 2015 Tumbleweed. All rights reserved.
//

import Foundation
import RealmSwift
import CoreLocation

class Location: Object {
    dynamic var lat = 0.0  // latitude
    dynamic var lng = 0.0  // longitude
    dynamic var address = ""
    dynamic var postalCode = ""
    dynamic var cc = ""
    dynamic var city = ""
    dynamic var state = ""
    dynamic var country = ""
    var formattedAddress : String {
        return address + "\n" + city + ", " + cc + "  " + postalCode
    }
    
    func distanceFrom (loc: CLLocation) -> (CLLocationDistance, String){
        //TODO: returns km now, but should be able to handle miles
        return ((loc.distanceFromLocation(CLLocation.init(latitude: lat,longitude: lng)))/1000.0, "km")
    }
    
    
    
}

class Venue: Object {
    dynamic var id = ""
    dynamic var name = ""
    var nameJPTransliterated: String {
        return ((name as NSString).stringByTransliteratingJapaneseToRomajiWithWordSeperator(" ") as String).capitalizedString
    }
    dynamic var location : Location?
    
    dynamic var hours = ""
    dynamic var tips = ""
    dynamic var rating = 0.0
    
    dynamic var photoUrl = ""
    dynamic var photoData : NSData = NSData()
    
    override static func primaryKey() -> String? {
        return "id"
    }
}
