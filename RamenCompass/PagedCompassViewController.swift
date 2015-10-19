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
    var pageCount = 0
    
    var delegatec: CompassViewControllerDelegate?
    
    var venueResults = try! Realm().objects(Venue.self).sorted("name", ascending: true) {
        didSet{
            setViewControllers([venueResultAtIndex(0)], direction: .Forward, animated: false, completion: nil)
            pageCount = venueResults.count
            print("reset venue results \(venueResults)")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        reset()
        
        dataSource = self
        delegate = self

        
        let pageControlHeight: CGFloat = 50
        pageControl = UIPageControl(frame: CGRect(x: 0, y: CGRectGetHeight(view.frame) - pageControlHeight, width: CGRectGetWidth(view.frame), height: pageControlHeight))
        pageControl.numberOfPages = pageCount
        pageControl.currentPage = 0
        
        pageControl.addTarget(self, action: "pageControlChanged:", forControlEvents: .ValueChanged)
        
        view.addSubview(pageControl)
        
    }
    
    func pageControlChanged(pageControl: UIPageControl) {
        // get the current and upcoming page numbers
        let currentCompassVC = venueResults.indexOf((viewControllers?.first as! CompassViewController).selectedRamen)!
        let upcomingCompassVC = pageControl.currentPage
        
        // what direction are we moving in?
        let direction: UIPageViewControllerNavigationDirection = upcomingCompassVC < currentCompassVC ? .Reverse : .Forward
        
        // set the new page, animated!
        setViewControllers([venueResultAtIndex(upcomingCompassVC)],
            direction: direction, animated: true, completion: nil)
    }
    func reset() {
        venueResults = try! Realm().objects(Venue.self).sorted("name", ascending: true)
    }
    func venueResultAtIndex(index: Int) -> CompassViewController {
        let compassVC = UIStoryboard.centerViewController()
        compassVC!.selectedRamen = venueResults[index]
        return compassVC!
    }
}

extension PagedCompassViewController: UIPageViewControllerDataSource {
    func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
        if let _ = viewController as? CompassViewController {
            
            if pageControl.currentPage < pageCount - 1 {
                return venueResultAtIndex(pageControl.currentPage+1)
            } else {
                return venueResultAtIndex(0)
            }
        }
        return nil
    }
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {
        if let _ = viewController as? CompassViewController {
            
            if pageControl.currentPage > 0 {
                return venueResultAtIndex(pageControl.currentPage-1)
            } else {
                return venueResultAtIndex(pageCount-1)
            }
        }
        return nil
    }
    
//    
//    func presentationCountForPageViewController(pageViewController: UIPageViewController) -> Int {
//        return pageCount
//    }
//    
//    func presentationIndexForPageViewController(pageViewController: UIPageViewController) -> Int {
//        if let currentCompassVC = pageViewController.viewControllers?.first as? CompassViewController {
//            return venueResults.indexOf(currentCompassVC.selectedRamen)!
//        }
//        return 0
//    }

}

extension PagedCompassViewController: UIPageViewControllerDelegate {
    func pageViewController(pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if let currentCompassVC = pageViewController.viewControllers?.first as? CompassViewController {
            pageControl.currentPage = venueResults.indexOf(currentCompassVC.selectedRamen)!
            print(pageCount)
            print(pageControl.currentPage)
        }
    }
}
