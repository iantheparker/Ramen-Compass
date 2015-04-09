//
//  MapViewController.swift
//  Ramen Compass
//
//  Created by Ian Parker on 2/20/15.
//  Copyright (c) 2015 Tumbleweed. All rights reserved.
//

import UIKit
import MapKit
import Realm

class MapViewController: UIViewController, MKMapViewDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    let kDistanceMeters:CLLocationDistance = 2000
    var userLocated:Bool = false
    //var ramenResults:Dictionary()
    
    func mapView(mapView: MKMapView!, didUpdateUserLocation userLocation: MKUserLocation!) {
        println("mapview got user lat \(userLocation.coordinate.latitude) and long \(userLocation.coordinate.longitude)")
        centerToUsersLocation()
        
    }
    func mapView(mapView: MKMapView!, viewForAnnotation annotation: MKAnnotation!) -> MKAnnotationView! {
        
        if annotation is MKUserLocation {
            //return nil so map view draws "blue dot" for standard user location
            return nil
        }
        
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId) as? MKPinAnnotationView
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = true
            pinView!.animatesDrop = true
            pinView!.pinColor = .Red
            var detailDisclosure = UIButton.buttonWithType(UIButtonType.DetailDisclosure) as! UIButton
            pinView!.rightCalloutAccessoryView = detailDisclosure
        }
        else {
            pinView!.annotation = annotation
        }
        
        return pinView
        
    }
    
    func mapView(mapView: MKMapView!, didAddAnnotationViews views: [AnyObject]!) {
        
        for annotationView in views as! [MKAnnotationView] {
            if (annotationView.annotation is RamenAnnotation) {
                annotationView.transform = CGAffineTransformMakeTranslation(0, -500)
                UIView.animateWithDuration(0.5, delay: 0.0, options: .CurveLinear, animations: {
                    annotationView.transform = CGAffineTransformMakeTranslation(0, 0)
                    }, completion: nil)
            }
        }
        
    }
    
    func populateMap() {
        mapView.removeAnnotations(mapView.annotations)
        let realm = RLMRealm.defaultRealm()
        let venues = Venue.allObjectsInRealm(realm)  // 1
        
        // Create annotations for each one
        for venue in venues { // 2
            let aVenue = venue as! Venue
            let coord = CLLocationCoordinate2D(latitude: aVenue.location.lat, longitude: aVenue.location.lng)
            let venueAnno = RamenAnnotation(coordinate: coord, title: aVenue.name, subtitle: aVenue.location.postalCode, venue: aVenue) as RamenAnnotation
            mapView.addAnnotation(venueAnno)
        }
    }

    @IBAction func centerToUsersLocation() {
        var mapCenter = mapView.userLocation.coordinate
        println("real mapCenter: \(mapCenter.latitude), \(mapCenter.longitude)")
        var zoomRegion : MKCoordinateRegion!
//        if ((abs(mapCenter.latitude - nycCoord.0) >= tolerance) || (abs(mapCenter.longitude - nycCoord.1) >= tolerance)){
//            let alertController = UIAlertController(title: "No Dishes Nearby", message: "You're too far away. Get your ass to NYC first!", preferredStyle: .Alert)
//            let alertAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Destructive, handler: {(alert : UIAlertAction!) in
//                alertController.dismissViewControllerAnimated(true, completion: nil)
//            })
//            alertController.addAction(alertAction)
//            presentViewController(alertController, animated: true, completion: nil)
//            
//            mapCenter = CLLocationCoordinate2D(latitude: 40.73, longitude: -73.99)
//            zoomRegion = MKCoordinateRegionMakeWithDistance(mapCenter, kDistanceMeters*10, kDistanceMeters*10)
//        }
//        else{
//            zoomRegion = MKCoordinateRegionMakeWithDistance(mapCenter, kDistanceMeters, kDistanceMeters)
//            
//        }
        zoomRegion = MKCoordinateRegionMakeWithDistance(mapCenter, kDistanceMeters, kDistanceMeters)
        mapView.setRegion(zoomRegion, animated: false);
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.userTrackingMode = MKUserTrackingMode.FollowWithHeading
        populateMap()

        //modalTransitionStyle = UIModalTransitionStyle.FlipHorizontal
    }
    
    override func viewWillAppear(animated: Bool) {
        //modalTransitionStyle = UIModalTransitionStyle.FlipHorizontal
    }

}
