////
//  ViewController.swift
//  Ramen Compass
//
//  Created by Ian Parker on 2/19/15.
//  Copyright (c) 2015 Tumbleweed. All rights reserved.
//

import UIKit
import RealmSwift
import MapKit

@objc
protocol CompassViewControllerDelegate {
    optional func mapButtonPressed()
    optional func detailButtonPressed()
    func toggleTopPanel()
    func toggleBottomPanel()
    func collapseSidePanels()
}


class CompassViewController: UIViewController {
    
    //let realm = RLMRealm(path: NSBundle.mainBundle().resourcePath!.stringByAppendingPathComponent("ramcom.realm"), readOnly: true, error: nil)

    var selectedRamen: Venue! {
        didSet{
//            NSNotificationCenter.defaultCenter().postNotificationName("selectedRamenChanged", object: self, userInfo: ["selectedRamen":selectedRamen])
//            print("set notif for selectedRamen")
            updateDisplayedRamen()
        }
    }

    @IBOutlet weak var chopsticksImage : UIImageView!
    @IBOutlet weak var bowlView: UIView!
    @IBOutlet weak var venueNameEN: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    
    var delegate: CompassViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Styling the UI
        self.title = "RAMEN COMPASS" // ラーメン　コンパス
        //loadingChopsticksAnimation()
        //let tapRecognizer = UITapGestureRecognizer(target: self, action: "bowlTapped:")
        //bowlView.addGestureRecognizer(tapRecognizer)
        updateDisplayedRamen()
    }
    
    //MARK: - Update Display Methods
    
    
    func updateDisplayedRamen(){
        //need to make sure
        guard let selectedRamen = selectedRamen else { return }
        
        print("selectedRamen.description = \(selectedRamen.name)")
        
        if (NSString.stringContainsJapaneseText((selectedRamen.name as NSString) as String)){
            //venueNameJP.text = selectedRamen.name.uppercaseString
            venueNameEN.text = selectedRamen.nameJPTransliterated
        }
        else{
            print(selectedRamen.name)
            venueNameEN?.text = selectedRamen.name
            //venueNameEN.center = CGPointMake(venueNameEN.center.x, (venueNameJP.center.y - 15))
            //venueNameJP.hidden = true
            //print(venueNameEN.font)
        }
        
        let font = UIFont(name: "Whitney-Light", size: 60.0) ?? UIFont.systemFontOfSize(18.0)
        let textFont = [NSFontAttributeName:font]
//        let distanceString = String(format: "%0.1f", selectedRamen.location!.distanceFrom(currentLocation).0)
//        let attributedString = NSMutableAttributedString(string: distanceString, attributes: textFont)
//        attributedString.appendAttributedString( NSAttributedString(string: " km", attributes: [NSFontAttributeName:UIFont(name: "Whitney-Bold", size: 15.0)!]))
        distanceLabel?.text = "WTF"
//        distanceLabel.attributedText = attributedString
        //cityLabel.text = "in " + (selectedRamen.location?.city ?? "Somewhere")
        //println(attributedString)

        //FIXME: updateheading may not be the best place for this
        //stopChopsticksAnimation()
        
    }
    
    

        
    
    //MARK: - Chopstick Rotation and Animation Methods
    
    func loadingChopsticksAnimation(){
        let fullRotation = CGFloat(M_PI)
        print("load")
        UIView.animateWithDuration(0.2, delay:0, options: UIViewAnimationOptions.Repeat , animations: {
            self.chopsticksImage.transform = CGAffineTransformMakeRotation(fullRotation)
            return
            }, completion: nil)
    }
    func stopChopsticksAnimation(){
        
        UIView.animateWithDuration(2.0, delay: 0.3, usingSpringWithDamping: 0.8, initialSpringVelocity: 1.0, options: UIViewAnimationOptions.CurveEaseInOut,
            animations: {
                self.chopsticksImage.transform = CGAffineTransformMakeRotation(CGFloat(0))
                return
            }, completion: nil)
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
        
        var degrees = (radToDeg(atan2(sin(tLng-fLng)*cos(tLat), cos(fLat)*sin(tLat)-sin(fLat)*cos(tLat)*cos(tLng-fLng))) % 360 )
        
        if(degrees<0){
            degrees = -degrees
        } else {
            degrees = 360 - degrees
        }
        return degrees
    }
    
    func rotateChopsticksTowardHeading(newHeading: CLHeading){
        // TODO: this should be tapped into nsnotification coming from header
        let radians = newHeading.trueHeading * (M_PI/180.0)
        //println("radians = \(radians), Updated heading to \(newHeading)")
        guard let selectedRamen = selectedRamen else { return }
        
        let venueLoc = CLLocationCoordinate2DMake(selectedRamen.location!.lat, selectedRamen.location!.lng)
        let course = getHeadingForDirection(currentLocation.coordinate, toLoc: venueLoc)
        print("course = \(course)")
        
        self.chopsticksImage.layer.anchorPoint = CGPointMake(0.5, 0.5)
        var transform = CATransform3DIdentity
        transform.m34 = -1.0/1000.0
        let tilt = CATransform3DMakeRotation(CGFloat(degToRad(25)), 1, 0, 0)
        //transform = CATransform3DMakeTranslation(0, 60, 0)
        let rotation = CATransform3DMakeRotation(CGFloat(self.degToRad(course)-radians), 0, 0, 1)
        transform = CATransform3DConcat(tilt, rotation)
        self.chopsticksImage.layer.transform = transform
        self.chopsticksImage.layer.zPosition = 500
        
    }
}



extension CompassViewController: DetailViewControllerDelegate{
    
    func addressDirectionButtonPressed() {
        
        if (UIApplication.sharedApplication().canOpenURL(
            NSURL(string: "comgooglemaps://")!) == false){
                openAppleMapDirections()
                print("no google maps")
                return
        }
        
        let optionMenu = UIAlertController(title: nil, message: "You can go your own waaaay", preferredStyle: .ActionSheet)
        
        let googleAction = UIAlertAction(title: "Google Maps", style: .Default, handler: {
            (alert: UIAlertAction!) -> Void in
            print("Open Google Maps")
            UIApplication.sharedApplication().openURL(NSURL(string:"comgooglemaps://?saddr=\(currentLocation.coordinate.latitude),\(currentLocation.coordinate.longitude)&daddr=\(self.selectedRamen.location!.lat),\(self.selectedRamen.location!.lng)&directionsmode=walking")!)
        })
        let appleAction = UIAlertAction(title: "Apple Maps", style: .Default, handler: {
            (alert: UIAlertAction!) -> Void in
            print("Open Apple Maps")
            self.openAppleMapDirections()
            
        })
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: {
            (alert: UIAlertAction!) -> Void in
            print("Cancelled")
        })
        
        optionMenu.addAction(googleAction)
        optionMenu.addAction(appleAction)
        optionMenu.addAction(cancelAction)
        
        self.presentViewController(optionMenu, animated: true, completion: nil)
    }
    
    func openAppleMapDirections(){
        print("openAppleMapDirections pressed")
        if selectedRamen == nil {return}
        
        let coordinates = CLLocationCoordinate2DMake(selectedRamen.location!.lat, selectedRamen.location!.lng)
        let options = [MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeDriving]
        let placemark =  MKPlacemark(coordinate: coordinates, addressDictionary: nil)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = "\(selectedRamen.name)"
        mapItem.openInMapsWithLaunchOptions(options)
    }
}

extension CompassViewController: MapViewControllerDelegate{
    
    func ramenSelected(venue: Venue, animated: Bool) {
        if animated{
            //delegate?.detailButtonPressed()
        }
        //selectedRamenIndex = venueResults[venResSection].indexOf(venue)!
    }
}


