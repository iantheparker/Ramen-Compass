//
//  ViewController.swift
//  Ramen Compass
//
//  Created by Ian Parker on 2/19/15.
//  Copyright (c) 2015 Tumbleweed. All rights reserved.
//

import UIKit
import CoreLocation
import Realm

class CompassViewController: UIViewController, CLLocationManagerDelegate {
    
    let clientId = valueForAPIKey(keyname:  "clientId")
    let clientSecret = valueForAPIKey(keyname:  "clientSecret")
    
    let locationManager = CLLocationManager()
    var locationFixAchieved : Bool = false
    var currentLocation : CLLocation!
    var selectedRamen: Venue!
    var notificationToken: RLMNotificationToken?
    
    @IBOutlet weak var chopsticksImage : UIImageView!
    @IBOutlet weak var bowlView: UIView!
    @IBOutlet weak var venueName: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var mapButton: UIButton!
    
    @IBAction func mapButtonPressed() {
        
        println("hit mapButtonPressed")
        //var vc = self.storyboard?.instantiateViewControllerWithIdentifier("map") as MapViewController
        //modalTransitionStyle = .PartialCurl
        //self.presentViewController(vc, animated: true, completion: nil)
    }
    
    @IBAction func refreshLocation(){
        locationFixAchieved = false
        locationManager.startUpdatingLocation()
        //select closest
    }
    
    func updateDisplayedRamen(){
        //need to make sure
        selectedRamen = Venue.allObjects().objectAtIndex(0) as Venue
        println(selectedRamen.description)
        
        venueName.text = selectedRamen.name.uppercaseString
        let ramenll: CLLocation = CLLocation.init(latitude: selectedRamen.location.lat,longitude: selectedRamen.location.lng)
        distanceLabel.text = String(format: "%0.1f km", currentLocation.distanceFromLocation(ramenll)/1000.0) //this isn't calculated by locationmanager
        locationManager.startUpdatingHeading()
    }
    
    @IBAction func panBowl(sender: UIPanGestureRecognizer) {
        println("bowlpan = \(sender.translationInView(bowlView)) in vcview \(sender.translationInView(self.view))")
        var angle = atan2f(Float(sender.translationInView(self.view).x), Float(sender.translationInView(self.view).y))
        
        var initialRotation: Float
        
        initialRotation = atan2f(Float(sender.view!.transform.b), Float(sender.view!.transform.a))
        self.bowlView.transform = CGAffineTransformMakeRotation(CGFloat(-angle))
    }
    
    func degToRad(degrees: Double) -> Double
    {
        return (M_PI * degrees / 180.0)
    }
    
    func radToDeg(radians: Double) -> Double
    {
        return (radians * 180.0 / M_PI)
    }

    func getHeadingForDirection (fromLoc: CLLocationCoordinate2D, toLoc: CLLocationCoordinate2D) -> Double
    {
        let fLat = degToRad(fromLoc.latitude)
        let fLng = degToRad(fromLoc.longitude)
        let tLat = degToRad(toLoc.latitude)
        let tLng = degToRad(toLoc.longitude)
        
        return (radToDeg(atan2(sin(tLng-fLng)*cos(tLat), cos(fLat)*sin(tLat)-sin(fLat)*cos(tLat)*cos(tLng-fLng))) % 360 )
    }
    
    
    func searchVenues(coord: CLLocation) {
        let url = NSURL(string: "https://api.foursquare.com/v2/venues/search?client_id=\(clientId)&client_secret=\(clientSecret)&v=20150215&ll=\(coord.coordinate.latitude),\(coord.coordinate.longitude)&categoryId=4bf58dd8d48988d1d1941735&intent=browse&radius=2000")
        let request = NSURLRequest(URL:url!)

        NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue.mainQueue()) {response, data, error in
            if data != nil {
                let json: AnyObject! = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers, error: nil)
                if let venues = (json["response"] as? NSDictionary)?["venues"] as? [NSDictionary] {
                    self.setUpRealm(venues)
                }
            }
            if error != nil {
                let alert = UIAlertView(title:"Get a better connection!",message:error.localizedDescription, delegate:nil, cancelButtonTitle:"OK")
                alert.show()
            }
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
        }
    }
    
    func setUpRealm(venues: [NSDictionary]) {
        let realm = RLMRealm.defaultRealm()
        realm.beginWriteTransaction()
        realm.deleteAllObjects()
        // Save one Venue object (and dependents) for each element of the array
        for venue in venues {
            Venue.createOrUpdateInDefaultRealmWithObject(venue)
        }
        realm.commitWriteTransaction()
    }
    
    // MARK: - LocationManager
    func locationManager(manager: CLLocationManager!, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        
        switch status {
        case .Authorized, .AuthorizedWhenInUse:
            println("Authorized")
            locationManager.startUpdatingLocation()
        case .NotDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .Restricted, .Denied:
            let alertController = UIAlertController(
                title: "Location Access Disabled",
                message: "In order to find delicious bowls of ramen near you, please open this app's settings and set location access to 'When In Use'.",
                preferredStyle: .Alert)
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
            alertController.addAction(cancelAction)
            
            let openAction = UIAlertAction(title: "Open Settings", style: .Default) { (action) in
                if let url = NSURL(string:UIApplicationOpenSettingsURLString) {
                    UIApplication.sharedApplication().openURL(url)
                }
            }
            alertController.addAction(openAction)
            
            self.presentViewController(alertController, animated: true, completion: nil)
        }
        
    }
    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
        var locationArray = locations as NSArray
        currentLocation = locationArray.lastObject as CLLocation
        println(currentLocation)
        if (locationFixAchieved == false) {
            locationFixAchieved = true
            searchVenues(currentLocation)
        }
    }
    
    func locationManager(manager: CLLocationManager!, didUpdateHeading newHeading: CLHeading!) {
        var radians = newHeading.trueHeading * (M_PI/180.0)
        println("radians = \(radians), Updated heading to \(newHeading)")
        var venueLoc = CLLocationCoordinate2DMake(selectedRamen.location.lat, selectedRamen.location.lng)
        var course = getHeadingForDirection(currentLocation.coordinate, toLoc: venueLoc)
        
        UIView.animateWithDuration(0.2,
            delay: 0.0,
            options: .CurveEaseInOut,
            animations: {
                self.chopsticksImage.transform = CGAffineTransformMakeRotation(CGFloat(self.degToRad(course)-radians))
            },
            completion: { finished in
        })
        
    }
    
    func locationManager(manager: CLLocationManager!, didFailWithError error: NSError!) {
        println("i'm on loc error")
        println(error.localizedDescription)
        locationManager.stopUpdatingLocation()
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        
        if (segue.identifier == "map") {
            let controller = segue.destinationViewController as MapViewController
        }
        else if (segue.identifier == "RamenDetail") {
            let controller = segue.destinationViewController as VenueViewController
            controller.fsqpage = selectedRamen.id
            //println("conad \(self.selectedRamen.id)")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Styling the UI
        self.title = "RAMEN COMPASS" // ラーメン　コンパス
        let titleDict: NSDictionary = [NSForegroundColorAttributeName: UIColor.whiteColor(), NSKernAttributeName: 200.0, NSFontAttributeName: UIFont(name: "HouschkaAltHeavy", size: 20)!]
        self.navigationController!.navigationBar.titleTextAttributes = titleDict
        mapButton.layer.cornerRadius = 5.0
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 100
        locationManager.pausesLocationUpdatesAutomatically = true
        locationManager.headingFilter = 2
        locationFixAchieved = false
        
        if (CLLocationManager.authorizationStatus() == .NotDetermined) {
            locationManager.requestWhenInUseAuthorization()
            println("Requesting Authorization")
        } else {
            locationManager.startUpdatingLocation()
            println("starting location manager")
        }
        
        notificationToken = RLMRealm.defaultRealm().addNotificationBlock { note, realm in
            println("notif block")
            self.updateDisplayedRamen()
        }
    }

    


}

