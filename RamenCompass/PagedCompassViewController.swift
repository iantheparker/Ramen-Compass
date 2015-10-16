//
//  PagedCompassViewController.swift
//  RamenCompass
//
//  Created by Ian Parker on 10/9/15.
//  Copyright © 2015 Tumbleweed. All rights reserved.
//

import Foundation
import UIKit
import RealmSwift

class PagedCompassViewController: UIPageViewController {
    var pageControl: UIPageControl!
    
    var delegatec: CompassViewControllerDelegate?
    
    var pageCount = 5
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        reset()
        
        dataSource = self
        
        let pageControlHeight: CGFloat = 50
        pageControl = UIPageControl(frame: CGRect(x: 0, y: CGRectGetHeight(view.frame) - pageControlHeight, width: CGRectGetWidth(view.frame), height: pageControlHeight))
        pageControl.numberOfPages = pageCount
        pageControl.currentPage = 0
        
        // uber solution - connect the action
        pageControl.addTarget(self, action: "pageControlChanged:", forControlEvents: .ValueChanged)
        
        view.addSubview(pageControl)
        
        delegate = self
    }
    
//    // uber solution - action method
//    func pageControlChanged(pageControl: UIPageControl) {
//        // get the current and upcoming page numbers
//        let currentTutorialPage = (viewControllers[0] as! TutorialStepViewController).page
//        let upcomingTutorialPage = pageControl.currentPage
//        
//        // what direction are we moving in?
//        let direction: UIPageViewControllerNavigationDirection = upcomingTutorialPage < currentTutorialPage ? .Reverse : .Forward
//        
//        // set the new page, animated!
//        setViewControllers([tutorialStepForPage(upcomingTutorialPage)],
//            direction: direction, animated: true, completion: nil)
//    }
    func reset () {
        let poo = UIStoryboard.centerViewController()
        poo!.selectedRamen = try! Realm().objects(Venue.self)[0]
        setViewControllers([poo!], direction: .Forward, animated: false, completion: nil)
        pageCount = try! Realm().objects(Venue.self).count
        
    }
}

extension PagedCompassViewController: UIPageViewControllerDataSource {
    func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
        if let currentTutorialPage = viewController as? CompassViewController {
            
            if pageControl.currentPage < pageCount - 1 {
                pageControl.currentPage++
                let poo = UIStoryboard.centerViewController()
                poo!.selectedRamen = try! Realm().objects(Venue.self)[pageControl.currentPage]
                return poo
            } else {
                pageControl.currentPage=0
                let poo = UIStoryboard.centerViewController()
                poo!.selectedRamen = try! Realm().objects(Venue.self)[pageControl.currentPage]
                return poo
            }
        }
        return nil
    }
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {
        if let currentTutorialPage = viewController as? CompassViewController {
            
            if pageControl.currentPage > 0 {
                pageControl.currentPage--
                let poo = UIStoryboard.centerViewController()
                poo!.selectedRamen = try! Realm().objects(Venue.self)[pageControl.currentPage]
                return poo
            } else {
                pageControl.currentPage = pageCount-1
                let poo = UIStoryboard.centerViewController()
                poo!.selectedRamen = try! Realm().objects(Venue.self)[pageControl.currentPage]
                return poo
            }
        }
        return nil
    }
    
    /* Code to activate the built-in page control */
    /*
    func presentationCountForPageViewController(pageViewController: UIPageViewController) -> Int {
    return pageCount
    }
    
    func presentationIndexForPageViewController(pageViewController: UIPageViewController) -> Int {
    if let currentTutorialPage = pageViewController.viewControllers[0] as? TutorialStepViewController {
    return currentTutorialPage.page
    }
    return 0
    }
    */
}

extension PagedCompassViewController: UIPageViewControllerDelegate {
    func pageViewController(pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if let currentTutorialPage = pageViewController.viewControllers?.first as? CompassViewController {
            //pageControl.currentPage = currentTutorialPage.page
        }
    }
}
