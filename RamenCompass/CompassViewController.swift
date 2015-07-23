//
//  ViewController.swift
//  Ramen Compass
//
//  Created by Ian Parker on 2/19/15.
//  Copyright (c) 2015 Tumbleweed. All rights reserved.
//

import UIKit
import CoreLocation
import RealmSwift
import MapKit


protocol CompassViewControllerDelegate {
    func mapButtonPressed()
    func detailButtonPressed()
}


class CompassViewController: UIViewController {
    
    lazy var locationManager = CLLocationManager()
    var locationFixAchieved : Bool = false
    var locationCC: String = ""
    var currentLocation : CLLocation!
    
    var notificationToken: NotificationToken?
    //let realm = RLMRealm(path: NSBundle.mainBundle().resourcePath!.stringByAppendingPathComponent("ramcom.realm"), readOnly: true, error: nil)
    var venueResults = [Results<Venue>]()
    let venResSection = 0
    var selectedRamen: Venue! {
        didSet{
            NSNotificationCenter.defaultCenter().postNotificationName("selectedRamenChanged", object: self, userInfo: ["selectedRamen":selectedRamen])
            println("set notif for selectedRamen")
        }
    }

    @IBOutlet weak var chopsticksImage : UIImageView!
    @IBOutlet weak var bowlView: UIView!
    @IBOutlet weak var venueNameJP: UILabel!
    @IBOutlet weak var venueNameEN: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var cityLabel: UILabel!
    @IBOutlet weak var mapButton: PopButton!
    @IBOutlet weak var leftButton : PopButton!
    @IBOutlet weak var rightButton : PopButton!
    @IBOutlet weak var refreshButton: PopButton!
    
    var delegate: CompassViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Styling the UI
        self.title = "RAMEN COMPASS" // ラーメン　コンパス
        //loadingChopsticksAnimation()
        let tapRecognizer = UITapGestureRecognizer(target: self, action: "bowlTapped:")
        bowlView.addGestureRecognizer(tapRecognizer)
        
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
        
        NSFileManager.defaultManager().removeItemAtPath(Realm().path, error: nil)
        notificationToken = Realm().addNotificationBlock { [unowned self] note, realm in
            println("CompassVC notif block")
            self.setupVenueResults()
            self.selectedRamenIndex = 0
        }

}
    
    func setupVenueResults(){
        //let unsortedVenues = Realm().objects(Venue).filter(" ")
        venueResults.removeAll(keepCapacity: false)
        let sortedVenues = Realm().objects(Venue).sorted("name", ascending: true)
        venueResults.append(sortedVenues)
    }
    
    //MARK: - Update Display Methods
    
    private var _selectedRamenIndex: Int = 0
    var selectedRamenIndex : Int{
        get {
            return self._selectedRamenIndex
        }
        set{
            if Int(venueResults[venResSection].count) > 0{
                leftButton.enabled = true
                rightButton.enabled = true
                
                var newIndex = newValue
                if (newIndex < 0){
                    newIndex = Int(venueResults[venResSection].count)-1
                }
                else if (newIndex > Int(venueResults[venResSection].count)-1){
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
    func venueForIndexPath(indexPath: NSIndexPath) -> Venue? {
        //println("venueResults in venueForIndexPath = \(venueResults)")
        return venueResults[indexPath.section][indexPath.row]
    }
    
    func updateDisplayedRamen(){
        //need to make sure
        if let selectedRamenTest = venueForIndexPath(NSIndexPath(forRow: selectedRamenIndex, inSection: venResSection)){
            
            selectedRamen = selectedRamenTest
            println("selectedRamen.description at \(selectedRamenIndex) = \(selectedRamen.name)")
            
            if (NSString.stringContainsJapaneseText((selectedRamen.name as NSString) as String)){
                venueNameJP.text = selectedRamen.name.uppercaseString
                venueNameEN.text = selectedRamen.nameJPTransliterated
            }
            else{
                venueNameEN.text = selectedRamen.name
                venueNameEN.center = CGPointMake(venueNameEN.center.x, (venueNameJP.center.y - 15))
                venueNameJP.hidden = true
                println(venueNameEN.font)
            }
            
            let font = UIFont(name: "Whitney-Light", size: 60.0) ?? UIFont.systemFontOfSize(18.0)
            let textFont = [NSFontAttributeName:font]
            let distanceString = String(format: "%0.1f", selectedRamen.location.distanceFrom(currentLocation).0)
            var attributedString = NSMutableAttributedString(string: distanceString, attributes: textFont)
            attributedString.appendAttributedString( NSAttributedString(string: " km", attributes: [NSFontAttributeName:UIFont(name: "Whitney-Bold", size: 15.0)!]))
            //distanceLabel.text = distanceString ?? "WTF"
            distanceLabel.attributedText = attributedString
            cityLabel.text = "in " + (selectedRamen.location.city ?? "Somewhere")
            //println(attributedString)

            //FIXME: updateheading may not be the best place for this
            locationManager.startUpdatingHeading()
            stopChopsticksAnimation()
        }
        
    }
    
    
    //MARK: - Button Actions
    @IBAction func leftObject(sender: AnyObject) {
        selectedRamenIndex -= 1
    }
    
    @IBAction func rightObject(sender: AnyObject) {
        selectedRamenIndex += 1
    }
    
    @IBAction func mapButtonPressed(sender: AnyObject) {
        delegate?.mapButtonPressed()
        println("map button pressed")
    }
    
    @IBAction func refreshLocation(){
        locationFixAchieved = false
        loadingChopsticksAnimation()
        
        if let
            masterVC = self.parentViewController as? MasterViewController,
            mapVC = masterVC.childViewControllers[0] as? MapViewController
            where masterVC.topVCIsOpen()
        {
            println("top is open")
            Foursquare.sharedInstance.searchWithDetails(mapVC.getMapCenterCoord(), radius: nil)
        }else{
            locationManager.startUpdatingLocation()
        }

    }
    
    
    //MARK: - Chopstick Rotation and Animation Methods
    
    func loadingChopsticksAnimation(){
        let fullRotation = CGFloat(M_PI)
        println("load")
        UIView.animateWithDuration(0.2, delay:0, options: .Repeat | .CurveLinear, animations: {
            self.chopsticksImage.transform = CGAffineTransformMakeRotation(fullRotation)
            return
            }, completion: nil)
    }
    func stopChopsticksAnimation(){
        
        UIView.animateWithDuration(2.0, delay: 0.3, usingSpringWithDamping: 0.8, initialSpringVelocity: 1.0, options: .BeginFromCurrentState | .CurveEaseInOut,
            animations: {
                self.chopsticksImage.transform = CGAffineTransformMakeRotation(CGFloat(0))
                return

            }, completion: nil)

    }
    
    func bowlTapped(sender: UITapGestureRecognizer){
        var scaleAnimation: POPBasicAnimation = POPBasicAnimation(propertyNamed: kPOPLayerScaleXY)
        scaleAnimation.toValue = NSValue(CGSize: CGSizeMake(0.90, 0.90))
        bowlView.layer.pop_addAnimation(scaleAnimation, forKey: "layerScaleSmallAnimation")
        
        var scaleAnimation1: POPSpringAnimation = POPSpringAnimation(propertyNamed: kPOPLayerScaleXY)
        scaleAnimation1.velocity = NSValue(CGSize: CGSizeMake(3.0, 3.0))
        scaleAnimation1.toValue = NSValue(CGSize: CGSizeMake(1.0, 1.0))
        scaleAnimation1.springBounciness = 10.0
        bowlView.layer.pop_addAnimation(scaleAnimation1, forKey: "layerScaleSpringAnimation")
        
        //delegate?.detailButtonPressed()
    }
    
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

extension CompassViewController: CLLocationManagerDelegate{
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
            Foursquare.sharedInstance.searchWithDetails(currentLocation, radius: nil)
        
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
}

extension CompassViewController: DetailViewControllerDelegate{
    
    func addressDirectionButtonPressed() {
        
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
        if selectedRamen == nil {return}
        
        var coordinates = CLLocationCoordinate2DMake(selectedRamen.location.lat, selectedRamen.location.lng)
        var options = [MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeDriving]
        var placemark =  MKPlacemark(coordinate: coordinates, addressDictionary: nil)
        var mapItem = MKMapItem(placemark: placemark)
        mapItem.name = "\(selectedRamen.name)"
        mapItem.openInMapsWithLaunchOptions(options)
    }
}

extension CompassViewController: MapViewControllerDelegate{
    
    func ramenSelected(venue: Venue, animated: Bool) {
        if animated{
            delegate?.detailButtonPressed()
        }
        selectedRamenIndex = venueResults[venResSection].indexOf(venue)!
    }
}


