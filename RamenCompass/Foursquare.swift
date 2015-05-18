//
//  Foursquare.swift
//  RamenCompass
//
//  Created by Ian Parker on 4/9/15.
//  Copyright (c) 2015 Tumbleweed. All rights reserved.
//

import UIKit
import RealmSwift
import CoreLocation

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
    
    //MARK: - Foursquare GET VENUES
    
    func searchVenues(coord: CLLocation) {
        //update this line here also move it to a foursquare class?
        let myradius = "200"
        let url = NSURL(string: "https://api.foursquare.com/v2/venues/search?client_id=\(clientId)&client_secret=\(clientSecret)&v=20150215&ll=\(coord.coordinate.latitude),\(coord.coordinate.longitude)&categoryId=4bf58dd8d48988d1d1941735&intent=browse&radius=\(myradius)")
        let request = NSURLRequest(URL:url!)
        
        NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue.mainQueue()) {response, data, error in
            if data != nil {
                let json: AnyObject! = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers, error: nil)
                if let
                    res     = json["response"] as? [String: AnyObject],
                    venues  = res["venues"] as? [NSDictionary]
                {
                    self.setUpAutoRealm("", venues: venues)
                }
            }
            if error != nil {
                let alert = UIAlertView(title:"Get a better connection!",message:error.localizedDescription, delegate:nil, cancelButtonTitle:"OK")
                alert.show()
            }
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
        }
    }
    
    func getListVenues(coord: CLLocation) {
        //200 ramen list id
        let ramenListId = "4e5fada1483b8637b3d0372c"
        let llTolerance = 0.5
        let url = NSURL(string: "https://api.foursquare.com/v2/lists/\(ramenListId)?client_id=\(clientId)&client_secret=\(clientSecret)&v=20150215")
        let request = NSURLRequest(URL:url!)
        
        NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue.mainQueue()) {response, data, error in
            if data != nil {
                let json: AnyObject! = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers, error: nil)
                //println(json)
                //list{listItems{items({
                if let
                    res         = json["response"] as? [String: AnyObject],
                    list        = res["list"] as? [String: AnyObject],
                    listItems   = list["listItems"] as? [String: AnyObject],
                    venues      = listItems["items"] as? [NSDictionary]
                {
                    self.setUpAutoRealm("list",venues: venues)
                }
            }
            if error != nil {
                let alert = UIAlertView(title:"Get a better connection!",message:error.localizedDescription, delegate:nil, cancelButtonTitle:"OK")
                alert.show()
            }
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
        }
    }
    
    //MARK: - Realm DB Creation
    
    func setUpAutoRealm(type: String , venues: [NSDictionary]) {
        
        let realm = Realm()
        realm.write {
            // Save one Venue object (and dependents) for each element of the array
            for venue in venues {
                if (type == "list"){
                    realm.create(Venue.self, value: venue["venue"]!, update: true)

                }else {realm.create(Venue.self, value: venue, update: true)}
                //println(venue)
            }
        }
        
        //FIXME: use the copy of this realm
        //realm.writeCopyToPath("/Users/ianparker/Documents/code/RamenCompass/ramcom_new.realm", error: nil)
        
        //TODO: reset selectedRamen OR choose closest
        //FIXME: setting the index from here could recursively call updateDisplay when paired with the realmNotif block
        //selectedRamenIndex = 0
    }
    
    
    
}


