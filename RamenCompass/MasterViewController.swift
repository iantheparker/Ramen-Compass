//
//  MasterViewController.swift
//  RamenCompass
//
//  Created by Ian Parker on 5/17/15.
//  Copyright (c) 2015 Tumbleweed. All rights reserved.
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
            toggleBottomPanel()
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
            if (currentState == .BothCollapsed) {
                if (gestureIsDraggingFromLeftToRight) {
                    addTopPanelViewController()
                } else {
                    addBottomPanelViewController()
                }
                
                showShadowForCenterViewController(true)
                hideStatusBar = true
                
            }
        case .Changed:
            recognizer.view!.center.y = recognizer.view!.center.y + recognizer.translationInView(view).y
            recognizer.setTranslation(CGPointZero, inView: view)
        case .Ended:
            if (topViewController != nil) {
                // animate the side panel open or closed based on whether the view has moved more or less than halfway
                let hasMovedGreaterThanHalfway = recognizer.view!.center.y > view.bounds.size.height
                animateTopPanel(shouldExpand: hasMovedGreaterThanHalfway)
            } else if (bottomViewController != nil) {
                let hasMovedGreaterThanHalfway = recognizer.view!.center.y < 0
                animateBottomPanel(shouldExpand: hasMovedGreaterThanHalfway)
            }
            hideStatusBar = false
        default:
        
            break
        }
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return hideStatusBar
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

class MasterViewController: UIViewController {
    var topViewcontroller: MapViewController!
    var mainViewController: CompassViewController!
    var bottomViewController: DetailViewController!
    var overlap: CGFloat!
    var scrollView: UIScrollView!
    var firstTime = true
    private var hideStatusBar: Bool = false
    var page1pos : CGFloat = 0
    var page2pos : CGFloat = 0
    var page3pos : CGFloat = 0

    
    required init?(coder aDecoder: NSCoder) {
        assert(false, "Use init(leftViewController:mainViewController:overlap:)")
        super.init(coder: aDecoder)
    }
    
    init(topViewcontroller: MapViewController, mainViewController: CompassViewController, bottomViewController: DetailViewController, overlap: CGFloat) {
        self.mainViewController = mainViewController
        self.bottomViewController = bottomViewController
        self.topViewcontroller = topViewcontroller

        self.overlap = overlap
        
        super.init(nibName: nil, bundle: nil)
        
        self.bottomViewController.delegate = mainViewController
        self.mainViewController.delegate = self
        self.topViewcontroller.delegate = mainViewController

        
        setupScrollView()
        setupViewControllers()
        self.view.backgroundColor = UIColor.blackColor()

    }
    
    override func viewDidLayoutSubviews() {
        if firstTime {
            firstTime = false
            closeTopAnimated(false)
        }
    }
    
    
    func setupScrollView() {
        scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.pagingEnabled = false
        scrollView.decelerationRate = UIScrollViewDecelerationRateFast
        scrollView.bounces = false
        scrollView.clipsToBounds = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.directionalLockEnabled = true
        scrollView.delegate = self
        view.addSubview(scrollView)
        
        let horizontalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("H:|[scrollView]|", options: [], metrics: nil, views: ["scrollView": scrollView])
//        let scrollHeightConstraint = NSLayoutConstraint(
//            item: scrollView,
//            attribute: .Height,
//            relatedBy: .Equal,
//            toItem: view,
//            attribute: .Height,
//            multiplier: 1.0, constant: -overlap)
        let verticalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("V:|[scrollView]|", options: [], metrics: nil, views: ["scrollView": scrollView])
        NSLayoutConstraint.activateConstraints(horizontalConstraints + verticalConstraints) // [] had scrollHeightConstrant
        
        let tapRecognizer = UITapGestureRecognizer(target: self, action: "viewTapped:")
        tapRecognizer.delegate = self
        view.addGestureRecognizer(tapRecognizer)
    }
    
    func setupViewControllers() {
        addViewController(mainViewController)
        addViewController(bottomViewController)
        addViewController(topViewcontroller)
        
        addShadowToView(mainViewController.view)
        addGradientToView(mainViewController.view)
        
        let views = ["top": topViewcontroller.view, "main": mainViewController.view, "bottom": bottomViewController.view, "outer": view]
        
        let horizontalConstraints = NSLayoutConstraint.constraintsWithVisualFormat(
            "|[main(==outer)]|", options: [] , metrics: nil, views: views)
        let topHeightConstraint = NSLayoutConstraint(
            item: topViewcontroller.view,
            attribute: .Height,
            relatedBy: .Equal,
            toItem: view,
            attribute: .Height,
            multiplier: 1.0, constant: -overlap)
        let bottomHeightConstraint = NSLayoutConstraint(
            item: bottomViewController.view,
            attribute: .Height,
            relatedBy: .Equal,
            toItem: view,
            attribute: .Height,
            multiplier: 1.0, constant: -overlap)
        let verticalConstraints = NSLayoutConstraint.constraintsWithVisualFormat(
            "V:|[top][main(==outer)][bottom]|", options: [.AlignAllLeft, .AlignAllRight], metrics: nil, views: views)
        NSLayoutConstraint.activateConstraints(horizontalConstraints + verticalConstraints + [topHeightConstraint, bottomHeightConstraint])
        
        page1pos = 0
        page2pos = CGRectGetHeight(self.view.frame) - overlap
        page3pos = page2pos * 2
    
    }
    
    private func addViewController(viewController: UIViewController) {
        viewController.view.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(viewController.view)
        addChildViewController(viewController)
        viewController.didMoveToParentViewController(self)
    }
    
    private func addShadowToView(destView: UIView) {
        destView.layer.masksToBounds = false
        destView.layer.shadowPath = UIBezierPath(rect: destView.bounds).CGPath
        destView.layer.shadowRadius = 4.0
        destView.layer.shadowOffset = CGSize(width: 0, height: -50)
        destView.layer.shadowOpacity = 0.5
        destView.layer.shadowColor = UIColor.blackColor().CGColor
    }
    
    private func addGradientToView( destView: UIView) {
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = CGRectMake(0, page1pos, destView.frame.width, destView.frame.height * 2)
        gradientLayer.colors = [UIColor(rgba: "#FEF5CC").CGColor as CGColorRef,
            UIColor(rgba: "#F2C86A").CGColor as CGColorRef]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0, y: 1)
        destView.layer.insertSublayer(gradientLayer, atIndex: 0)
    }
    
    func closeTopAnimated(animated: Bool) {
        scrollView.setContentOffset(CGPoint(x: 0, y: page2pos), animated: animated)
    }
    
    func topVCIsOpen() -> Bool {
        return scrollView.contentOffset.y == 0
    }
    
    func bottomVCIsOpen() -> Bool {
        return scrollView.contentOffset.y == page3pos
    }
    
    func openTopVCAnimated(animated: Bool) {
        scrollView.setContentOffset(CGPoint(x: 0, y: 0), animated: animated)
    }
    
    func openBottomVCAnimated(animated: Bool) {
        scrollView.setContentOffset(CGPoint(x: 0, y: page3pos), animated: animated)
    }
    
    func toggleTopAnimated(animated: Bool) {
        if topVCIsOpen() {
            closeTopAnimated(animated)
        } else {
            openTopVCAnimated(animated)
        }
    }
    
    func toggleBottomAnimated(animated: Bool) {
        if bottomVCIsOpen() {
            closeTopAnimated(animated)
        } else {
            openBottomVCAnimated(animated)
        }
    }
    func viewTapped(tapRecognizer: UITapGestureRecognizer) {
        closeTopAnimated(true)
    }
    
}

extension MasterViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {
        let tapLocation = touch.locationInView(view)
        let tapWasInTopOverlapArea = tapLocation.y <= overlap
        let tapWasInBottomOverlapArea = tapLocation.y >= CGRectGetHeight(view.bounds) - overlap
        
        if ((tapWasInBottomOverlapArea && topVCIsOpen()) || (tapWasInTopOverlapArea && (!topVCIsOpen() && !bottomVCIsOpen()))){
            if (tapLocation.x >= CGRectGetWidth(view.bounds)/6 && tapLocation.x <= CGRectGetWidth(view.bounds) * 5/6) {
                mainViewController.mapButton.sendActionsForControlEvents(UIControlEvents.TouchUpInside)
            }
            else {return true}
        } else if ((tapWasInBottomOverlapArea && !bottomVCIsOpen()) || (tapWasInTopOverlapArea && bottomVCIsOpen())){
            if (tapLocation.x >= CGRectGetWidth(view.bounds)/6 && tapLocation.x <= CGRectGetWidth(view.bounds) * 5/6) {
                toggleBottomAnimated(true)
            }
            else {return true}
        }
        
        return false
        
    }
}

extension MasterViewController: UIScrollViewDelegate{
    
    func scrollViewDidScroll(scrollView: UIScrollView) {

        
        if (scrollView.contentOffset.y == page1pos){
            UIView.transitionWithView(mainViewController.mapButton, duration: 0.2, options: UIViewAnimationOptions.TransitionFlipFromBottom, animations: { () -> Void in
                self.mainViewController.mapButton.selected = true
                }, completion: nil)
        }
        if (scrollView.contentOffset.y == page2pos){
            if (hideStatusBar){
                hideStatusBar = false
                UIView.animateWithDuration(0.3, animations: { () -> Void in
                    self.setNeedsStatusBarAppearanceUpdate()
                    self.mainViewController.view.bounds = CGRectMake(0, 0, self.view.bounds.width, self.view.bounds.height)
                    }, completion: { (Bool) -> Void in})
            }
            UIView.transitionWithView(mainViewController.mapButton, duration: 0.2, options: UIViewAnimationOptions.TransitionFlipFromTop, animations: { () -> Void in
                self.mainViewController.mapButton.selected = false
            }, completion: nil)
            
        }
        else {
            if (!hideStatusBar){
                hideStatusBar = true
                UIView.animateWithDuration(0.1, animations: { () -> Void in
                    self.setNeedsStatusBarAppearanceUpdate()
                    self.mainViewController.view.bounds = CGRectMake(0, 10, self.view.bounds.width, self.view.bounds.height)
                    }, completion: { (Bool) -> Void in})
            }
        }
    }
    
    func scrollViewWillEndDragging(scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        
        var scrollOffset = targetContentOffset.memory.y
        print("#1 \(scrollOffset) page2 \(page2pos) page3 \(page3pos) velocity \(velocity)", terminator: "")
        
        if ((scrollOffset >= page1pos) && (scrollOffset < page2pos)){
            if (fabs(scrollOffset - page1pos) < fabs(scrollOffset - page2pos)){
                scrollOffset = page1pos
            }else{
                scrollOffset = page2pos
            }
            
        }else if ((scrollOffset >= page2pos) && (scrollOffset <= page3pos)){
            if (fabs(scrollOffset - page2pos) < fabs(scrollOffset - page3pos)){
                scrollOffset = page2pos
            }else{
                scrollOffset = page3pos
            }
        }

        
        if (velocity.y > 2 && scrollOffset < page3pos) {
            targetContentOffset.memory.y = scrollOffset + page2pos
        }else if (velocity.y < -2 && scrollOffset > page1pos) {
            targetContentOffset.memory.y = scrollOffset - page2pos
        }else{
            targetContentOffset.memory.y = scrollOffset
        }
            
        
        

        print("#2 \(scrollOffset)", terminator: "")
        
    }
    
    func whichPage(){
        
    }
    
    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        
        var scrollOffset = scrollView.contentOffset.y
        
        if ((scrollOffset >= page1pos) && (scrollOffset < page2pos)){
            if (fabs(scrollOffset - page1pos) < fabs(scrollOffset - page2pos)){
                scrollOffset = page1pos
            }else{
                scrollOffset = page2pos
            }
            
        }else if ((scrollOffset >= page2pos) && (scrollOffset <= page3pos)){
            if (fabs(scrollOffset - page2pos) < fabs(scrollOffset - page3pos)){
                scrollOffset = page2pos
            }else{
                scrollOffset = page3pos
            }
        }
        UIView.animateWithDuration(0.33, delay: 0, options: .CurveEaseInOut, animations: { () -> Void in
                self.scrollView.contentOffset.y = scrollOffset
                }, completion: nil)
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return hideStatusBar
    }
    override func preferredStatusBarUpdateAnimation() -> UIStatusBarAnimation {
        return .Slide
    }
}

extension MasterViewController: CompassViewControllerDelegate{
    func mapButtonPressed() {
        toggleTopAnimated(true)
    }
    func detailButtonPressed() {
        toggleBottomAnimated(true)
    }
    func toggleTopPanel() {
        //
    }
    func toggleBottomPanel() {
        //
    }
    func collapseSidePanels() {
        //
    }
}
