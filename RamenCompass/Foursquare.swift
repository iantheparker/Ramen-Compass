////
//  Foursquare.swift
//  RamenCompass
//
//  Created by Ian Parker on 4/9/15.
//  Copyright (c) 2015 Tumbleweed. All rights reserved.
//

import UIKit
import RealmSwift
import CoreLocation
import Alamofire

let versionDate = "20151005"
private let clientId = valueForAPIKey(keyname:  "clientId")
private let clientSecret = valueForAPIKey(keyname:  "clientSecret")

class Foursquare: NSObject {
    
    var venueResults = [Results<Venue>]()

    
    class var sharedInstance: Foursquare {
        
        struct Singleton {
            
            static let instance = Foursquare()
        }
        
        return Singleton.instance
    }
    
    //MARK: - Foursquare GET VENUES
    
    func search(coord: CLLocation, radius: String?=nil, completionHandler: (NSArray?, NSError?) -> ()) -> (){
        
        //let radius = radius ?? "200"
        let limit = 10
        
        Alamofire.request(.GET,  "https://api.foursquare.com/v2/venues/search?client_id=\(clientId)&client_secret=\(clientSecret)&v=\(versionDate)&ll=\(coord.coordinate.latitude),\(coord.coordinate.longitude)&categoryId=4bf58dd8d48988d1d1941735&limit=\(limit)", parameters: nil)
            .responseJSON { ( request, response, result) in
                
                if let
                    data    = result.value as? NSDictionary,
                    res     = data["response"] as? [String: AnyObject],
                    venues   = res["venues"] as? [NSDictionary]
                {
                    completionHandler(venues, nil)
                }else{
                    //self.showAlert(result.error!)
                }
        }
    }
    
    func getVenueDetails(id: String, completionHandler: (NSDictionary?, NSError?) -> ()) -> (){
        
        
        
        Alamofire.request(.GET,  "https://api.foursquare.com/v2/venues/\(id)?client_id=\(clientId)&client_secret=\(clientSecret)&v=\(versionDate)", parameters: nil)
            .responseJSON { _, _, result in
                
                if let
                    data    = result.value as? NSDictionary,
                    res     = data["response"] as? [String: AnyObject],
                    venue   = res["venue"] as? NSDictionary
                {
                    completionHandler(venue, nil)
                }else{
                    //self.showAlert(result.error!)
                }
        }
    }
    
    func getVenueDetailsFull(id: String, completionHandler: (Venue?, NSError?) -> ()) -> (){
        Alamofire.request(.GET,  "https://api.foursquare.com/v2/venues/\(id)?client_id=\(clientId)&client_secret=\(clientSecret)&v=\(versionDate)", parameters: nil)
            .responseJSON { _, _, result in
                
            if let
                    data    = result.value as? NSDictionary,
                    res     = data["response"] as? [String: AnyObject],
                    venue   = res["venue"] as? NSDictionary
                {
                    //return realm
                    let detailResponse = venue
                    let detailVenue = Venue()
                    detailVenue.id = (detailResponse["id"] as? String)!
                    detailVenue.name = (detailResponse["name"] as? String)!
                    if let rating = detailResponse["rating"] as? Double {detailVenue.rating = rating}
                    //println(detailResponse["location"] as? [String: AnyObject])
                    let loc = Location()
                        if let
                            location = detailResponse["location"] as? [String: AnyObject],
                            address = location["address"] as? String,
                            postalCode = location["postalCode"] as? String,
                            cc = location["cc"] as? String,
                            city = location["city"] as? String,
                            state = location["state"] as? String,
                            country = location["country"] as? String,
                            lat = location["lat"] as? Double,
                            lng = location["lng"] as? Double
                        {
                            loc.address = address
                            loc.postalCode = postalCode
                            loc.cc = cc
                            loc.city = city
                            loc.state = state
                            loc.country = country
                            loc.lat = lat
                            loc.lng = lng
                            detailVenue.location = loc
                        }
                    
                    if let
                        bestPhoto = detailResponse["bestPhoto"] as? [String: AnyObject],
                        imgprefix = bestPhoto["prefix"] as? String,
                        imgsuffix = bestPhoto["suffix"] as? String
                    {
                        detailVenue.photoUrl = imgprefix + "300x300" + imgsuffix
                    }
                    if let
                        timeframes = (detailResponse["hours"] as? [String: AnyObject])? ["timeframes"] as? [NSDictionary]
                    {
                        for timeframe in timeframes{
                            if let
                                hours = timeframe as? [String: AnyObject],
                                days = hours["days"] as? String,
                                open = hours["open"] as? [NSDictionary],
                                // TODO: need to handle beyond index 0 here 
                                renderedTime = open[0]["renderedTime"] as? String
                            {
                                detailVenue.hours += days + " " + renderedTime + " "
                            }
                        }
                    }
                    if let
                        phrases = detailResponse["phrases"] as? [NSDictionary]
                    {
                        for phrase in phrases{
                            if let
                                keyPhrase = phrase["phrase"] as? String
                            {
                                detailVenue.tips += keyPhrase + ", "
                            }
                        }
                        print("\(detailVenue.id) = \(detailVenue.tips)")
                    }
                    completionHandler(detailVenue, nil)
                    try! Realm().write{
                        try! Realm().add(detailVenue, update: true)
                    }
                }
            }

    
    }
    
    func searchWithDetails(coord: CLLocation, radius: String?=nil) {
        self.search(coord, radius: radius) {( response, error) ->() in
            if (error != nil){
                print(error)
            }else {
                let venues = response as! [NSDictionary]
                let realm = try! Realm()
                var poo = [Venue]()
                realm.beginWrite()
                    for venue in venues {
                        realm.create(Venue.self, value: venue, update: true)
                        self.getVenueDetailsFull((venue["id"] as? String)!, completionHandler: { (venueDeets, error) -> () in
                            if (error == nil){
                                poo.append(venueDeets!)
                                //println(" venuedeets \(venueDeets)")
                                //realm.add(venueDeets!, update: true)//(Venue.self, value: venueDeets!, update: true)
                            }
                        })
                    }
                realm.commitWrite()
            }
        }
    }
    
    
    func getListVenues(coord: CLLocation) {
        //200 ramen list id
        let ramenListId = "4e5fada1483b8637b3d0372c"
        //let llTolerance = 0.5
        let url = NSURL(string: "https://api.foursquare.com/v2/lists/\(ramenListId)?client_id=\(clientId)&client_secret=\(clientSecret)&v=\(versionDate)")
        let request = NSURLRequest(URL:url!)
        
        NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue.mainQueue()) {response, data, error in
            if data != nil {
                let json: AnyObject!
                do {
                    json = try NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.MutableContainers)
                } catch _ {
                    json = nil
                }
                //println(json)
                //list{listItems{items({
                if let
                    res         = json["response"] as? [String: AnyObject],
                    list        = res["list"] as? [String: AnyObject],
                    listItems   = list["listItems"] as? [String: AnyObject],
                    venues      = listItems["items"] as? [NSDictionary]
                {
                    let realm = try! Realm()
                    realm.write {
                        for venue in venues {
                            realm.create(Venue.self, value: venue["venue"]!, update: true)
                        }
                    }
                }
            }
            if error != nil {
                self.showAlert(error!)
            }
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
        }
    }
    
    func searchVenues(coord: CLLocation) {
        //update this line here also move it to a foursquare class?
        let myradius = "200"
        let url = NSURL(string: "https://api.foursquare.com/v2/venues/search?client_id=\(clientId)&client_secret=\(clientSecret)&v=20150215&ll=\(coord.coordinate.latitude),\(coord.coordinate.longitude)&categoryId=4bf58dd8d48988d1d1941735&intent=browse&radius=\(myradius)")
        let request = NSURLRequest(URL:url!)
        
        NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue.mainQueue()) {response, data, error in
            if data != nil {
                let json: AnyObject!
                do {
                    json = try NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.MutableContainers)
                } catch _ {
                    json = nil
                }
                if let
                    res     = json["response"] as? [String: AnyObject],
                    venues  = res["venues"] as? [NSDictionary]
                {
                    print(venues)
                    self.setUpAutoRealm("", venues: venues)
                }
            }
            if error != nil {
                self.showAlert(error!)
            }
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
        }
    }
    
    //MARK: - Realm DB Creation
    
    func setUpAutoRealm(type: String , venues: [NSDictionary]) {
        
        let realm = try! Realm()
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
        try! Realm().writeCopyToPath("/Users/ianparker/Documents/code/RamenCompass/ramcom_new.realm", encryptionKey: nil)
        
        //TODO: reset selectedRamen OR choose closest
        //FIXME: setting the index from here could recursively call updateDisplay when paired with the realmNotif block
        //selectedRamenIndex = 0
    }
    
    func showAlert(error: NSError){
        let alert = UIAlertView(title:"Get a better connection!",message:error.localizedDescription, delegate:nil, cancelButtonTitle:"OK")
        alert.show()
    }
}

