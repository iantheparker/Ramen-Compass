//
//  ContainerViewController.swift
//  RamenCompass
//
//  Created by Ian Parker on 10/7/15.
//  Copyright © 2015 Tumbleweed. All rights reserved.
//


import UIKit
import QuartzCore

enum SlideOutState {
    case BothCollapsed
    case TopPanelExpanded
    case BottomPanelExpanded
}

class ContainerViewController: UIViewController {
    
    var compassNavigationController: UINavigationController!
    var compassViewController: CompassViewController!
    
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
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        compassViewController = UIStoryboard.centerViewController()
        compassViewController.delegate = self
        
        // wrap the centerViewController in a navigation controller, so we can push views to it
        // and display bar button items in the navigation bar
        compassNavigationController = UINavigationController(rootViewController: compassViewController)
        view.addSubview(compassNavigationController.view)
        addChildViewController(compassNavigationController)
        compassNavigationController.didMoveToParentViewController(self)
        compassNavigationController.navigationBarHidden = true
        
        addGradientToView(compassViewController.view)
        
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: "handlePanGesture:")
        compassNavigationController.view.addGestureRecognizer(panGestureRecognizer)
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
            //leftViewController!.animals = Animal.allCats()
            topViewController!.delegate = compassViewController
            view.insertSubview(topViewController!.view, atIndex: 0)
            addChildViewController(topViewController!)
            topViewController!.didMoveToParentViewController(self)
        }
    }
    
    func addBottomPanelViewController() {
        if (bottomViewController == nil) {
            bottomViewController = UIStoryboard.bottomViewController()
            //rightViewController!.animals = Animal.allDogs()
            
            bottomViewController!.delegate = compassViewController
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

private extension UIStoryboard {
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
    
}
