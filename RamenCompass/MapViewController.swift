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
    var mapPopulated = false
    var notificationToken: NotificationToken?

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector:"reload:", name: "selectedRamenChanged", object: nil)
        
        let panRecognizer = UIPanGestureRecognizer(target: self, action: "mapPanned:")
        panRecognizer.delegate = self
        mapView.addGestureRecognizer(panRecognizer)
        
        mapView.userTrackingMode = MKUserTrackingMode.Follow
        
        notificationToken = try! Realm().addNotificationBlock { [unowned self] note, realm in
            print("MapVC notif block")
            self.mapPopulated = false
        }
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
        if (notificationToken != nil) {
            try! Realm().removeNotification(notificationToken!)
        }
    }
    
    func reload( notification: NSNotification){
        
        if !mapPopulated{
            populateMap()
            mapPopulated = true
        }
        
        print("map reload notif ")
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
        print("populating map")
        mapView.removeAnnotations(mapView.annotations)
        let venues = try! Realm().objects(Venue).sorted("name", ascending: true)
        
        // Create annotations for each one
        for venue in venues {
            let aVenue = venue as Venue
            let coord = CLLocationCoordinate2D(latitude: aVenue.location!.lat, longitude: aVenue.location!.lng)
            let venueAnno = RamenAnnotation(coordinate: coord, title: aVenue.name, subtitle: aVenue.location!.address, venue: aVenue)
            mapView.addAnnotation(venueAnno)
        }
        
    }

    @IBAction func centerToUsersLocation() {
        let mapCenter = mapView.userLocation.coordinate
        print("real mapCenter: \(mapCenter.latitude), \(mapCenter.longitude)")
        let zoomRegion = MKCoordinateRegionMakeWithDistance(mapCenter, kDistanceMeters, kDistanceMeters)
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
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        
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
            let detailDisclosure = UIButton(type: UIButtonType.InfoLight)
            let imageview = UIImageView(frame: CGRectMake(0, 0, 50, 55))
            imageview.image = UIImage(named: "darkIcon")
            pinView!.leftCalloutAccessoryView = imageview
            pinView!.rightCalloutAccessoryView = detailDisclosure
            pinView!.rightCalloutAccessoryView?.tintColor = UIColor.redColor()
        }
        else {
            pinView!.annotation = annotation
        }
        return pinView
    }
    
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        if let ramen = view.annotation as? RamenAnnotation {
            print("ramen = \(ramen.venue.name)")
            delegate?.ramenSelected(ramen.venue, animated: false)
        }
    }
    
    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if control == view.rightCalloutAccessoryView {
            //println("Disclosure Pressed! \(view.annotation.subtitle)")
            
            if let ramen = view.annotation as? RamenAnnotation {
                print("ramen = \(ramen.venue.name)")
                delegate?.ramenSelected(ramen.venue, animated: true)
            }
        }
    }
    
    func mapView(mapView: MKMapView, didAddAnnotationViews views: [MKAnnotationView]) {
        
        for annotationView in views {
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
    func gestureRecognizer(_: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWithGestureRecognizer:UIGestureRecognizer) -> Bool {
        return true
    }
}
