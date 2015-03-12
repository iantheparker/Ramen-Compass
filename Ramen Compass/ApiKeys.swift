//
//  ApiKeys.swift
//  Ramen Compass
//
//  Created by Ian Parker on 3/12/15.
//  Copyright (c) 2015 Tumbleweed. All rights reserved.
//

import Foundation

func valueForAPIKey(#keyname:String) -> String {
    let filePath = NSBundle.mainBundle().pathForResource("ApiKeys", ofType:"plist")
    let plist = NSDictionary(contentsOfFile:filePath!)
    
    let value:String = plist?.objectForKey(keyname) as String
    return value
}