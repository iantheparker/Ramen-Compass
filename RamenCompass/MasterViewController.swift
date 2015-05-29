//
//  MasterViewController.swift
//  RamenCompass
//
//  Created by Ian Parker on 5/17/15.
//  Copyright (c) 2015 Tumbleweed. All rights reserved.
//

import UIKit

class MasterViewController: UIViewController {
    var topViewcontroller: CompassMapViewController!
    var mainViewController: CompassViewController!
    var bottomViewController: DetailViewController!
    var overlap: CGFloat!
    var scrollView: UIScrollView!
    var firstTime = true
    private var hideStatusBar: Bool = false

    
    
    required init(coder aDecoder: NSCoder) {
        assert(false, "Use init(leftViewController:mainViewController:overlap:)")
        super.init(coder: aDecoder)
    }
    
    init(topViewcontroller: CompassMapViewController, mainViewController: CompassViewController, bottomViewController: DetailViewController, overlap: CGFloat) {
        self.topViewcontroller = topViewcontroller
        self.mainViewController = mainViewController
        self.bottomViewController = bottomViewController
        self.overlap = overlap
        
        super.init(nibName: nil, bundle: nil)
        
        self.bottomViewController.delegate = mainViewController
        self.mainViewController.delegate = self
        
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
        scrollView.pagingEnabled = true
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
        NSLayoutConstraint.activateConstraints(horizontalConstraints + verticalConstraints + [scrollHeightConstraint]) // [] had scrollHeightConstrant
        
        let tapRecognizer = UITapGestureRecognizer(target: self, action: "viewTapped:")
        tapRecognizer.delegate = self
        // FIXME: buttons on side views are unresponsive
        view.addGestureRecognizer(tapRecognizer)
    }
    
    func setupViewControllers() {
        addViewController(topViewcontroller)
        addViewController(mainViewController)
        addViewController(bottomViewController)
        
        addShadowToView(mainViewController.view)
        
        scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: -overlap, right: 0)
        
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
        
        view.addGestureRecognizer(scrollView.panGestureRecognizer)
        

    }
    
    private func addViewController(viewController: UIViewController) {
        viewController.view.setTranslatesAutoresizingMaskIntoConstraints(false)
        scrollView.addSubview(viewController.view)
        addChildViewController(viewController)
        viewController.didMoveToParentViewController(self)
    }
    
    private func addShadowToView(destView: UIView) {
        destView.layer.shadowPath = UIBezierPath(rect: destView.bounds).CGPath
        destView.layer.shadowRadius = 5.5
        destView.layer.shadowOffset = CGSize(width: 0, height: 5)
        destView.layer.shadowOpacity = 1.0
        destView.layer.shadowColor = UIColor.blackColor().CGColor
    }
    
    func closeTopAnimated(animated: Bool) {
        scrollView.setContentOffset(CGPoint(x: 0, y: CGRectGetHeight(scrollView.frame)), animated: animated)
    }
    
    func topVCIsOpen() -> Bool {
        return scrollView.contentOffset.y == 0
    }
    
    func bottomVCIsOpen() -> Bool {
        return scrollView.contentOffset.y == CGRectGetHeight(scrollView.frame) * 2
    }
    
    func openTopVCAnimated(animated: Bool) {
        scrollView.setContentOffset(CGPoint(x: 0, y: 0), animated: animated)
    }
    
    func openBottomVCAnimated(animated: Bool) {
        scrollView.setContentOffset(CGPoint(x: 0, y: CGRectGetHeight(scrollView.frame) * 2), animated: animated)
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
        let tapWasInTopOverlapArea = tapLocation.y >= CGRectGetHeight(view.bounds) - overlap
        
        if (tapWasInTopOverlapArea && topVCIsOpen()){
            if (tapLocation.x <= CGRectGetWidth(view.bounds)/7) {

                mainViewController.mapButton.sendActionsForControlEvents(UIControlEvents.TouchUpInside)
            }
            else if (tapLocation.x >= CGRectGetWidth(view.bounds) * 6/7){
                mainViewController.refreshButton.sendActionsForControlEvents(UIControlEvents.TouchUpInside)
            }
            else {return true}
        } else if (tapWasInTopOverlapArea && !bottomVCIsOpen()){
            if (tapLocation.x <= CGRectGetWidth(view.bounds)/7) {
                
                mainViewController.leftButton.sendActionsForControlEvents(UIControlEvents.TouchUpInside)
            }
            else if (tapLocation.x >= CGRectGetWidth(view.bounds) * 6/7){
                mainViewController.rightButton.sendActionsForControlEvents(UIControlEvents.TouchUpInside)
            }
            else {return true}
        }
        
        //let tapWasInBottomOverlapArea = tapLocation.y <= overlap

        return false
        
    }
}

extension MasterViewController: UIScrollViewDelegate{
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        if (scrollView.contentOffset.y == 0){
            UIView.transitionWithView(mainViewController.mapButton, duration: 0.2, options: UIViewAnimationOptions.TransitionFlipFromBottom, animations: { () -> Void in
                self.mainViewController.mapButton.selected = true
                }, completion: nil)
        }
        if (scrollView.contentOffset.y == scrollView.frame.height){
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
