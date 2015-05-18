//
//  MapViewController.swift
//  Ramen Compass
//
//  Created by Ian Parker on 2/20/15.
//  Copyright (c) 2015 Tumbleweed. All rights reserved.
//

import UIKit
import MapKit
import RealmSwift

let kDistanceMeters:CLLocationDistance = 2000


class CompassMapViewController: UIViewController {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var centerButton: UIButton!

    var userLocated:Bool = false
    
    func populateMap() {
        mapView.removeAnnotations(mapView.annotations)
        let venues = Realm().objects(Venue)  // 1
        
        // Create annotations for each one
        for venue in venues { // 2
            let aVenue = venue as Venue
            let coord = CLLocationCoordinate2D(latitude: aVenue.location.lat, longitude: aVenue.location.lng)
            let venueAnno = RamenAnnotation(coordinate: coord, title: aVenue.name, subtitle: aVenue.location.postalCode, venue: aVenue) as RamenAnnotation
            mapView.addAnnotation(venueAnno)
        }
    }

    @IBAction func centerToUsersLocation() {
        var mapCenter = mapView.userLocation.coordinate
        println("real mapCenter: \(mapCenter.latitude), \(mapCenter.longitude)")
        var zoomRegion : MKCoordinateRegion!
        zoomRegion = MKCoordinateRegionMakeWithDistance(mapCenter, kDistanceMeters, kDistanceMeters)
        mapView.setRegion(zoomRegion, animated: true)
        
        centerButton.selected = false
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let panRecognizer = UIPanGestureRecognizer(target: self, action: "mapPanned:")
        panRecognizer.delegate = self
        mapView.addGestureRecognizer(panRecognizer)
        
        mapView.userTrackingMode = MKUserTrackingMode.FollowWithHeading
        populateMap()

    }
    func mapPanned(recognizer:UIPanGestureRecognizer) {
        centerButton.selected = true
    }
}

extension CompassMapViewController: MKMapViewDelegate{
    
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
    
}

extension CompassMapViewController: UIGestureRecognizerDelegate{
    func gestureRecognizer(UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWithGestureRecognizer:UIGestureRecognizer) -> Bool {
            return true
    }
}
