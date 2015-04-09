//
//  Foursquare.swift
//  RamenCompass
//
//  Created by Ian Parker on 4/9/15.
//  Copyright (c) 2015 Tumbleweed. All rights reserved.
//

import UIKit

class Foursquare: NSObject {
    
    private let clientId = valueForAPIKey(keyname:  "clientId")
    private let clientSecret = valueForAPIKey(keyname:  "clientSecret")
    
    class var sharedInstance: Foursquare {
        //2
        struct Singleton {
            //3
            static let instance = Foursquare()
        }
        //4
        return Singleton.instance
    }
    
    
    
    
    
}


