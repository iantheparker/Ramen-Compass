//
//  MasterViewController.swift
//  RamenCompass
//
//  Created by Ian Parker on 5/17/15.
//  Copyright (c) 2015 Tumbleweed. All rights reserved.
//

import UIKit

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

    
    
    required init(coder aDecoder: NSCoder) {
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
        scrollView.setTranslatesAutoresizingMaskIntoConstraints(false)
        scrollView.pagingEnabled = false
        scrollView.decelerationRate = UIScrollViewDecelerationRateFast
        scrollView.bounces = false
        scrollView.clipsToBounds = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.directionalLockEnabled = true
        scrollView.delegate = self
        view.addSubview(scrollView)
        
        let horizontalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("H:|[scrollView]|", options: nil, metrics: nil, views: ["scrollView": scrollView])
        let scrollHeightConstraint = NSLayoutConstraint(
            item: scrollView,
            attribute: .Height,
            relatedBy: .Equal,
            toItem: view,
            attribute: .Height,
            multiplier: 1.0, constant: -overlap)
        let verticalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("V:|[scrollView]|", options: nil, metrics: nil, views: ["scrollView": scrollView])
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
            "|[main(==outer)]|", options: nil , metrics: nil, views: views)
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
            "V:|[top][main(==outer)][bottom]|", options: .AlignAllLeft | .AlignAllRight, metrics: nil, views: views)
        NSLayoutConstraint.activateConstraints(horizontalConstraints + verticalConstraints + [topHeightConstraint, bottomHeightConstraint])
        
        page1pos = 0
        page2pos = CGRectGetHeight(self.view.frame) - overlap
        page3pos = page2pos * 2
    
    }
    
    private func addViewController(viewController: UIViewController) {
        viewController.view.setTranslatesAutoresizingMaskIntoConstraints(false)
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
        var layerNow: CALayer
        layerNow = self.mainViewController.view.layer.sublayers[0] as! CALayer
        var offset = scrollView.contentOffset.y - page2pos
        if (offset <= 0 ) {
            offset = 0
        }
        //layerNow.position = CGPointMake(layerNow.position.x, offset * 1.3)
        
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
        println("#1 \(scrollOffset) page2 \(page2pos) page3 \(page3pos) velocity \(velocity)")
        
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
            
        
        

        println("#2 \(scrollOffset)")
        
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
}
