//
//  ContainerViewController.swift
//  RamenCompass
//
//  Created by Ian Parker on 10/7/15.
//  Copyright © 2015 Tumbleweed. All rights reserved.
//


import UIKit
import QuartzCore
import CoreLocation
import RealmSwift

enum SlideOutState {
    case BothCollapsed
    case TopPanelExpanded
    case BottomPanelExpanded
}
public var currentLocation : CLLocation!


class ContainerViewController: UIViewController {
    
    lazy var locationManager: CLLocationManager = {
        let manager = CLLocationManager()
        manager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        manager.delegate = self
        manager.distanceFilter = 100
        manager.pausesLocationUpdatesAutomatically = true
        return manager
        }()
    var locationFixAchieved = false
    var locationCC: String = ""
    
    
    var compassNavigationController: UINavigationController!
    @IBOutlet weak var compassViewController: PagedCompassViewController!
    
    var currentState: SlideOutState = .BothCollapsed {
        didSet {
            let shouldShowShadow = currentState != .BothCollapsed
            showShadowForCenterViewController(shouldShowShadow)
        }
    }
    
    var topViewController: MapViewController?
    var bottomViewController: DetailViewController?
    
    let centerPanelExpandedOffset: CGFloat = 80
    private var hideStatusBar: Bool = false {
        didSet{
            UIView.animateWithDuration(0.2, animations: { () -> Void in
                self.view.bounds = CGRectMake(0, self.hideStatusBar ? 10 : 0, self.view.bounds.width, self.view.bounds.height)
                }, completion: { (Bool) -> Void in self.setNeedsStatusBarAppearanceUpdate()})
        }
    }
    var notificationToken: NotificationToken?

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if (CLLocationManager.authorizationStatus() == .NotDetermined) {
            locationManager.requestWhenInUseAuthorization()
            print("Requesting Authorization")
        } else if (CLLocationManager.authorizationStatus() == .Denied || CLLocationManager.authorizationStatus() == .Restricted){
            // TODO: handle case and turn this into a loading screen or sad empty bowl state.
            // wrap didChangeAuth into a method to handle all this and call it all here
        }
        else {
            locationManager.startUpdatingLocation()
            locationManager.startUpdatingHeading()
            print("starting location manager")
        }
        
        
        
        //let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: "handlePanGesture:")
        //compassNavigationController.view.addGestureRecognizer(panGestureRecognizer)
        notificationToken = try! Realm().addNotificationBlock { [unowned self] note, realm in
            print("CompassVC notif block")
            self.setupVenueResults()
        }

    }
    
    private func addGradientToView( destView: UIView) {
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = CGRectMake(0, 0, destView.frame.width, destView.frame.height * 2)
        gradientLayer.colors = [UIColor(rgba: "#FEF5CC").CGColor as CGColorRef,
            UIColor(rgba: "#F2C86A").CGColor as CGColorRef]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0, y: 1)
        destView.layer.insertSublayer(gradientLayer, atIndex: 0)
    }
    
    func setupVenueResults(){
        if compassViewController == nil {
            compassViewController = self.childViewControllers.last as? PagedCompassViewController
            compassViewController.delegatec = self
            
            // wrap the centerViewController in a navigation controller, so we can push views to it
            // and display bar button items in the navigation bar
            compassNavigationController = UINavigationController(rootViewController: compassViewController)
            view.addSubview(compassNavigationController.view)
            addChildViewController(compassNavigationController)
            compassNavigationController.didMoveToParentViewController(self)
            compassNavigationController.navigationBarHidden = true
            
            addGradientToView(compassViewController.view)
        }
        compassViewController.reset()
    }
    
    @IBAction func mapButtonPressed(sender: AnyObject) {
        //delegate?.mapButtonPressed!()
        //delegate?.toggleTopPanel()
        print("map button pressed")
    }
    
    @IBAction func refreshLocation(){
        //        locationFixAchieved = false
        //        //loadingChopsticksAnimation()
        //
        //        if let
        //            masterVC = self.parentViewController as? MasterViewController,
        //            mapVC = masterVC.childViewControllers[0] as? MapViewController
        //            where masterVC.topVCIsOpen()
        //        {
        //            print("top is open")
        //            Foursquare.sharedInstance.searchWithDetails(mapVC.getMapCenterCoord(), radius: nil)
        //        }else{
        //            locationManager.startUpdatingLocation()
        //        }
        
    }

}

extension ContainerViewController: CompassViewControllerDelegate {
    
    func toggleTopPanel() {
        let notAlreadyExpanded = (currentState != .TopPanelExpanded)
        
        if notAlreadyExpanded {
            addTopPanelViewController()
        }
        
        animateTopPanel(shouldExpand: notAlreadyExpanded)
    }
    
    func toggleBottomPanel() {
        let notAlreadyExpanded = (currentState != .BottomPanelExpanded)
        
        if notAlreadyExpanded {
            addBottomPanelViewController()
        }
        
        animateBottomPanel(shouldExpand: notAlreadyExpanded)
    }
    
    func collapseSidePanels() {
        switch (currentState) {
        case .BottomPanelExpanded:
            toggleBottomPanel()
        case .TopPanelExpanded:
            print("toggletop")
            toggleTopPanel()
        default:
            break
        }
    }
    
    func addTopPanelViewController() {
        if (topViewController == nil) {
            topViewController = UIStoryboard.topViewController()
            //topViewController!.delegate = compassViewController
            view.insertSubview(topViewController!.view, atIndex: 0)
            addChildViewController(topViewController!)
            topViewController!.didMoveToParentViewController(self)
        }
    }
    
    func addBottomPanelViewController() {
        if (bottomViewController == nil) {
            bottomViewController = UIStoryboard.bottomViewController()
            
            //bottomViewController!.delegate = compassViewController
            view.insertSubview(bottomViewController!.view, atIndex: 0)
            addChildViewController(bottomViewController!)
            bottomViewController!.didMoveToParentViewController(self)        }
    }
    
    func animateTopPanel(shouldExpand shouldExpand: Bool) {
        if (shouldExpand) {
            currentState = .TopPanelExpanded
            
            animateCenterPanelYPosition(targetPosition: CGRectGetHeight(compassNavigationController.view.frame) - centerPanelExpandedOffset)
        } else {
            animateCenterPanelYPosition(targetPosition: 0) { finished in
                self.currentState = .BothCollapsed
                
                //self.topViewController!.view.removeFromSuperview()
                //self.topViewController = nil;
            }
        }
    }
    
    func animateCenterPanelYPosition(targetPosition targetPosition: CGFloat, completion: ((Bool) -> Void)! = nil) {
        UIView.animateWithDuration(0.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .CurveEaseInOut, animations: {
            self.compassNavigationController.view.frame.origin.y = targetPosition
            }, completion: completion)
    }
    
    func animateBottomPanel(shouldExpand shouldExpand: Bool) {
        if (shouldExpand) {
            currentState = .BottomPanelExpanded
            
            animateCenterPanelYPosition(targetPosition: -CGRectGetHeight(compassNavigationController.view.frame) + centerPanelExpandedOffset)
        } else {
            animateCenterPanelYPosition(targetPosition: 0) { _ in
                self.currentState = .BothCollapsed
                
                //self.bottomViewController!.view.removeFromSuperview()
                //self.bottomViewController = nil;
            }
        }
    }
    
    func showShadowForCenterViewController(shouldShowShadow: Bool) {
        if (shouldShowShadow) {
            compassNavigationController.view.layer.shadowOpacity = 0.8
        } else {
            compassNavigationController.view.layer.shadowOpacity = 0.0
        }
    }
    
}

extension ContainerViewController: CLLocationManagerDelegate{
    //MARK: - LocationManager
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        
        switch status {
        case .AuthorizedAlways, .AuthorizedWhenInUse:
            print("Authorized")
            locationManager.startUpdatingLocation()
            locationManager.startUpdatingHeading()
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
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let locationArray = locations as NSArray
        currentLocation = locationArray.lastObject as! CLLocation
        print("my current location \(currentLocation)")
        if (locationFixAchieved == false) {
            locationFixAchieved = true
            Foursquare.sharedInstance.searchWithDetails(currentLocation, radius: nil)
            
        }
    }
    
    func locationManager(manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        // TODO: post notifs to each compassVC
        
    }
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        print("i'm on loc error")
        print(error.localizedDescription)
        locationManager.stopUpdatingLocation()
    }
}

extension ContainerViewController: UIGestureRecognizerDelegate {
    // MARK: Gesture recognizer
    
    func handlePanGesture(recognizer: UIPanGestureRecognizer) {
        let gestureIsDraggingFromLeftToRight = (recognizer.velocityInView(view).y > 0)
        
        switch(recognizer.state) {
        case .Began:
            //hideStatusBar = true
            if (currentState == .BothCollapsed) {
                if (gestureIsDraggingFromLeftToRight) {
                    addTopPanelViewController()
                } else {
                    addBottomPanelViewController()
                }
                
                showShadowForCenterViewController(true)
                
            }
        case .Changed:
            recognizer.view!.center.y = recognizer.view!.center.y + recognizer.translationInView(view).y
            recognizer.setTranslation(CGPointZero, inView: view)
        case .Ended:
            if self.currentState == .BothCollapsed {
                //hideStatusBar = false
            }
            if (topViewController != nil) {
                // animate the side panel open or closed based on whether the view has moved more or less than halfway
                let hasMovedGreaterThanHalfway = recognizer.view!.center.y > view.bounds.size.height
                animateTopPanel(shouldExpand: hasMovedGreaterThanHalfway)
            } else if (bottomViewController != nil) {
                let hasMovedGreaterThanHalfway = recognizer.view!.center.y < 0
                animateBottomPanel(shouldExpand: hasMovedGreaterThanHalfway)
            }
        default:
            
            break
        }
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true //hideStatusBar
    }
    override func preferredStatusBarUpdateAnimation() -> UIStatusBarAnimation {
        return .Slide
    }
    
}

extension UIStoryboard {
    class func mainStoryboard() -> UIStoryboard { return UIStoryboard(name: "Main", bundle: NSBundle.mainBundle()) }
    
    class func topViewController() -> MapViewController? {
        return mainStoryboard().instantiateViewControllerWithIdentifier("Map") as? MapViewController
    }
    
    class func bottomViewController() -> DetailViewController? {
        return mainStoryboard().instantiateViewControllerWithIdentifier("Detail") as? DetailViewController
    }
    
    class func centerViewController() -> CompassViewController? {
        return mainStoryboard().instantiateViewControllerWithIdentifier("Compass") as? CompassViewController
    }
    class func pagedViewController() -> PagedCompassViewController? {
        return mainStoryboard().instantiateViewControllerWithIdentifier("Page") as? PagedCompassViewController
    }
}
