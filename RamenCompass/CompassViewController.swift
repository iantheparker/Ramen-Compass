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
import MapKit


class CompassViewController: UIViewController, CLLocationManagerDelegate, UIScrollViewDelegate {
    
    let locationManager = CLLocationManager()
    var locationFixAchieved : Bool = false
    var locationCC: String = ""
    var currentLocation : CLLocation!
    private var hideStatusBar: Bool = false
    
    var notificationToken: RLMNotificationToken?
    var selectedRamen: Venue!
    //let realm = RLMRealm(path: NSBundle.mainBundle().resourcePath!.stringByAppendingPathComponent("ramcom.realm"), readOnly: true, error: nil)
    private var _selectedRamenIndex: Int = 0
    
    @IBOutlet weak var chopsticksImage : UIImageView!
    @IBOutlet weak var bowlView: UIView!
    @IBOutlet weak var venueNameJP: UILabel!
    @IBOutlet weak var venueNameEN: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var mapButton: UIButton!
    @IBOutlet weak var scrollView : UIScrollView!
    @IBOutlet weak var addressButton : PopButton!
    @IBOutlet weak var tipLabel : UILabel!
    @IBOutlet weak var hoursLabel : UILabel!
    @IBOutlet weak var photoIView : UIImageView!
    @IBOutlet weak var leftButton : PopButton!
    @IBOutlet weak var rightButton : PopButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        scrollView.delegate = self
        var swipeRight = UISwipeGestureRecognizer(target: self, action: "respondToSwipeGesture:")
        swipeRight.direction = UISwipeGestureRecognizerDirection.Right
        self.view.addGestureRecognizer(swipeRight)
        
        var swipeLeft = UISwipeGestureRecognizer(target: self, action: "respondToSwipeGesture:")
        swipeLeft.direction = UISwipeGestureRecognizerDirection.Left
        self.view.addGestureRecognizer(swipeLeft)
        
        // Styling the UI
        self.title = "RAMEN COMPASS" // ラーメン　コンパス
        let titleDict: NSDictionary = [NSForegroundColorAttributeName: UIColor.whiteColor(), NSKernAttributeName: 200.0, NSFontAttributeName: UIFont(name: "HouschkaAltHeavy", size: 20)!]
        self.navigationController!.navigationBar.titleTextAttributes = titleDict as [NSObject : AnyObject]
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
            //self.updateDisplayedRamen()
            self.selectedRamenIndex = 0
        }
    }
    
    
    //MARK: - LocationManager
    func locationManager(manager: CLLocationManager!, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        
        switch status {
        case .AuthorizedAlways, .AuthorizedWhenInUse:
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
        currentLocation = locationArray.lastObject as! CLLocation
        println("my current location \(currentLocation)")
        if (locationFixAchieved == false) {
            locationFixAchieved = true
            if (Venue.allObjects().count > 0){
                println("In loc, using realm")
                selectedRamenIndex=0
            }
            else{
                println("In loc, building realm")
                Foursquare.sharedInstance.getListVenues(currentLocation)
            }
            if (locationCC == ""){
                CLGeocoder().reverseGeocodeLocation(manager.location, completionHandler: { (placemarks, error) -> Void in
                    if (error != nil)
                    {
                        println("Reverse geocoder failed with error" + error.localizedDescription)
                        //pull location from map?
                        return
                    }
                    
                    if placemarks.count > 0
                    {
                        let pm = placemarks[0] as! CLPlacemark
                        self.locationCC = (pm.country != nil) ? pm.country : ""
                        if (self.locationCC == "Japan"){
    //                        if (Venue.allObjects().count > 0){
    //                            println("In Japan, using realm")
    //                        }
    //                        else{
    //                            println("In Japan, building realm")
    //                            self.getListVenues(manager.location)
    //                        }
                        }
                        else {
                            Foursquare.sharedInstance.searchVenues(manager.location)
                        }
                    }
                    else
                    {
                        println("Problem with the data received from geocoder")
                    }
                })
            }
            
        }
    }
    
    func locationManager(manager: CLLocationManager!, didUpdateHeading newHeading: CLHeading!) {
        var radians = newHeading.trueHeading * (M_PI/180.0)
        println("radians = \(radians), Updated heading to \(newHeading)")
        if (selectedRamen != nil){
            var venueLoc = CLLocationCoordinate2DMake(selectedRamen.location.lat, selectedRamen.location.lng)
            var course = getHeadingForDirection(currentLocation.coordinate, toLoc: venueLoc)
            println("course = \(course)")
            
            UIView.animateWithDuration(0.2,
                delay: 0.0,
                options: .CurveEaseInOut,
                animations: {
                    self.chopsticksImage.transform = CGAffineTransformMakeRotation(CGFloat(self.degToRad(course)-radians))
                },
                completion: { finished in
            })
        }
        
        
    }
    
    func locationManager(manager: CLLocationManager!, didFailWithError error: NSError!) {
        println("i'm on loc error")
        println(error.localizedDescription)
        locationManager.stopUpdatingLocation()
        venueNameJP.text = error.localizedDescription
    }


    //MARK: - Update Display Methods
    
    
    var selectedRamenIndex : Int{
        get {
            return self._selectedRamenIndex
        }
        set{
            if Venue.allObjects().count != 0{
                leftButton.enabled = true
                rightButton.enabled = true
                
                var newIndex = newValue
                if (newValue < 0){
                    newIndex = Int(Venue.allObjects().count)-1
                }
                else if (newValue > (Int(Venue.allObjects().count)-1)){
                    newIndex = 0
                }
                self._selectedRamenIndex = newIndex
                updateDisplayedRamen()
            }
            else {
                leftButton.enabled = false
                rightButton.enabled = false
            }
        }
    }
    
    func updateDisplayedRamen(){
        //need to make sure
        if let selectedRamenTest = Venue.allObjects().objectAtIndex(UInt(selectedRamenIndex)) as? Venue {
            
            selectedRamen = selectedRamenTest
            println(selectedRamen.description)
            
            
            
            venueNameJP.text = selectedRamen.name.uppercaseString
            venueNameEN.text = ((venueNameJP.text! as NSString).stringByTransliteratingJapaneseToRomajiWithWordSeperator(" ") as String).capitalizedString

            let ramenll: CLLocation = CLLocation.init(latitude: selectedRamen.location.lat,longitude: selectedRamen.location.lng)
            distanceLabel.text = String(format: "%0.1f km", currentLocation.distanceFromLocation(ramenll)/1000.0) //this isn't calculated by locationmanager
            let addressText = selectedRamen.location.address + "\n" + selectedRamen.location.city + ", " + selectedRamen.location.cc + "  " + selectedRamen.location.postalCode
            addressButton.setTitle(addressText, forState: UIControlState.Normal)
            //FIXME: sizeToFit is only working 10% of the time
            tipLabel.sizeToFit()
            //FIXME: updateheading may not be the best place for this
            locationManager.startUpdatingHeading()
        }
        
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        if (scrollView.contentOffset.y == 0){
            if (hideStatusBar){
                hideStatusBar = false
                UIView.animateWithDuration(0.3, animations: { () -> Void in
                    self.setNeedsStatusBarAppearanceUpdate()

                }, completion: { (Bool) -> Void in})
            }
        }
        else {
            if (!hideStatusBar){
                hideStatusBar = true
                UIView.animateWithDuration(0.1, animations: { () -> Void in
                    self.setNeedsStatusBarAppearanceUpdate()
                    
                    }, completion: { (Bool) -> Void in})
            }
        }
    }
    
    func respondToSwipeGesture(gesture: UIGestureRecognizer) {
        
        if let swipeGesture = gesture as? UISwipeGestureRecognizer {
            
            switch swipeGesture.direction {
            case UISwipeGestureRecognizerDirection.Right:
                println("Swiped right")
                leftBowl()
            case UISwipeGestureRecognizerDirection.Left:
                println("Swiped left")
                rightBowl()
            default:
                break
            }
        }
    }
    override func prefersStatusBarHidden() -> Bool {
        return hideStatusBar
    }
    override func preferredStatusBarUpdateAnimation() -> UIStatusBarAnimation {
        return .Slide
    }
    
    //MARK: - Button Actions
    
    @IBAction func leftBowl(){
        selectedRamenIndex -= 1
    }
    @IBAction func rightBowl(){
        selectedRamenIndex += 1
    }
    
    @IBAction func addressDirectionButtonPressed(sender: AnyObject) {
        
        if (UIApplication.sharedApplication().canOpenURL(
            NSURL(string: "comgooglemaps://")!) == false){
                openAppleMapDirections()
                println("no google maps")
                return
        }
        
        let optionMenu = UIAlertController(title: nil, message: "You can go your own waaaay", preferredStyle: .ActionSheet)
        
        let googleAction = UIAlertAction(title: "Google Maps", style: .Default, handler: {
            (alert: UIAlertAction!) -> Void in
            println("Open Google Maps")
            UIApplication.sharedApplication().openURL(NSURL(string:"comgooglemaps://?saddr=\(self.currentLocation.coordinate.latitude),\(self.currentLocation.coordinate.longitude)&daddr=\(self.selectedRamen.location.lat),\(self.selectedRamen.location.lng)&directionsmode=walking")!)
        })
        let appleAction = UIAlertAction(title: "Apple Maps", style: .Default, handler: {
            (alert: UIAlertAction!) -> Void in
            println("Open Apple Maps")
            self.openAppleMapDirections()
            
        })
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: {
            (alert: UIAlertAction!) -> Void in
            println("Cancelled")
        })
        
        optionMenu.addAction(googleAction)
        optionMenu.addAction(appleAction)
        optionMenu.addAction(cancelAction)
        
        self.presentViewController(optionMenu, animated: true, completion: nil)
    }
    
    func openAppleMapDirections(){
        println("openAppleMapDirections pressed")
        var coordinates = CLLocationCoordinate2DMake(selectedRamen.location.lat, selectedRamen.location.lng)
        var options = [MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeDriving]
        var placemark =  MKPlacemark(coordinate: coordinates, addressDictionary: nil)
        var mapItem = MKMapItem(placemark: placemark)
        mapItem.name = "\(selectedRamen.name)"
        mapItem.openInMapsWithLaunchOptions(options)
    }
    
    @IBAction func mapButtonPressed() {
        
        println("hit mapButtonPressed")
        //var vc = self.storyboard?.instantiateViewControllerWithIdentifier("map") as MapViewController
        //modalTransitionStyle = .PartialCurl
        //self.presentViewController(vc, animated: true, completion: nil)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        
        if (segue.identifier == "map") {
            let controller = segue.destinationViewController as! MapViewController
        }
        
    }
    
    @IBAction func refreshLocation(){
        locationFixAchieved = false
        locationManager.startUpdatingLocation()
    }
    
    
    //MARK: - Chopstick Rotation and Animation Methods
    
    @IBAction func panBowl(sender: UIPanGestureRecognizer) {
        //FIXME: need to offset origin of chopstick spin to center of bowl
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
    
    


    
    

}

