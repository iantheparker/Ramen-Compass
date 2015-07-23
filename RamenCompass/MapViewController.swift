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


protocol MapViewControllerDelegate{
    func ramenSelected(venue: Venue, animated: Bool)
}

class MapViewController: UIViewController {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var centerButton: UIButton!

    var userLocated:Bool = false
    var delegate : MapViewControllerDelegate?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector:"reload:", name: "selectedRamenChanged", object: nil)
        
        let panRecognizer = UIPanGestureRecognizer(target: self, action: "mapPanned:")
        panRecognizer.delegate = self
        mapView.addGestureRecognizer(panRecognizer)
        
        mapView.userTrackingMode = MKUserTrackingMode.Follow
        
        notificationToken = Realm().addNotificationBlock { [unowned self] note, realm in
            println("MapVC notif block")
            self.populateMap()
        }
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func reload( notification: NSNotification){
        println("map reload notif ")
        let userInfo = notification.userInfo as! [String: AnyObject]
        let detailSelectedRamen = userInfo["selectedRamen"] as! Venue?
        
        for annotation in mapView.annotations{
            if let anno = (annotation as? RamenAnnotation),
            venue = anno.venue
            where venue == detailSelectedRamen
            {
                mapView.selectAnnotation(anno, animated: true)
                centerButton.selected = true
                break
            }
        }
    }
    
    func populateMap() {
        println("populating map")
        mapView.removeAnnotations(mapView.annotations)
        let venues = Realm().objects(Venue).sorted("name", ascending: true)
        
        var firstPin = true
        var annotation: RamenAnnotation?
        // Create annotations for each one
        for venue in venues {
            let aVenue = venue as Venue
            let coord = CLLocationCoordinate2D(latitude: aVenue.location.lat, longitude: aVenue.location.lng)
            let venueAnno = RamenAnnotation(coordinate: coord, title: aVenue.name, subtitle: aVenue.location.address, venue: aVenue)
            mapView.addAnnotation(venueAnno)
            if firstPin{
                //annotation = venueAnno
                firstPin = false
            }
        }
        mapView.selectAnnotation(annotation, animated: true)
        
    }

    @IBAction func centerToUsersLocation() {
        var mapCenter = mapView.userLocation.coordinate
        println("real mapCenter: \(mapCenter.latitude), \(mapCenter.longitude)")
        var zoomRegion : MKCoordinateRegion!
        zoomRegion = MKCoordinateRegionMakeWithDistance(mapCenter, kDistanceMeters, kDistanceMeters)
        mapView.setRegion(zoomRegion, animated: true)
        
        centerButton.selected = false
    }
    
    func mapPanned(recognizer:UIPanGestureRecognizer) {
        centerButton.selected = true
    }
    
    func getMapCenterCoord() -> CLLocation{
        let center : CLLocation = CLLocation(latitude: mapView.centerCoordinate.latitude, longitude: mapView.centerCoordinate.longitude)
        return center
    }
}

extension MapViewController: MKMapViewDelegate{
    
    func mapView(mapView: MKMapView!, didUpdateUserLocation userLocation: MKUserLocation!) {
        println("mapview got user lat \(userLocation.coordinate.latitude) and long \(userLocation.coordinate.longitude)")
        if centerButton.selected == true {
            centerToUsersLocation()
        }
        
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
            var detailDisclosure = UIButton.buttonWithType(UIButtonType.InfoLight) as! UIButton
            var imageview = UIImageView(frame: CGRectMake(0, 0, 50, 55))
            imageview.image = UIImage(named: "darkIcon")
            pinView!.leftCalloutAccessoryView = imageview
            pinView!.rightCalloutAccessoryView = detailDisclosure
            pinView!.rightCalloutAccessoryView.tintColor = UIColor.redColor()
        }
        else {
            pinView!.annotation = annotation
        }
        return pinView
    }
    
    func mapView(mapView: MKMapView!, didSelectAnnotationView view: MKAnnotationView!) {
        if let ramen = view.annotation as? RamenAnnotation {
            println("ramen = \(ramen.venue.name)")
            delegate?.ramenSelected(ramen.venue, animated: false)
        }
    }
    
    func mapView(mapView: MKMapView!, annotationView view: MKAnnotationView!, calloutAccessoryControlTapped control: UIControl!) {
        if control == view.rightCalloutAccessoryView {
            //println("Disclosure Pressed! \(view.annotation.subtitle)")
            
            if let ramen = view.annotation as? RamenAnnotation {
                println("ramen = \(ramen.venue.name)")
                delegate?.ramenSelected(ramen.venue, animated: true)
            }
        }
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

extension MapViewController: UIGestureRecognizerDelegate{
    func gestureRecognizer(UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWithGestureRecognizer:UIGestureRecognizer) -> Bool {
        return true
    }
}
