//
//  MonthPagingViewController.swift
//  Calendar-Month-View
//
//  Created by Nick Lanasa on 9/9/14.
//

import Foundation
import UIKit

enum SwipeDirection {
    case SwipeDirectionLeft
    case SwipeDirectionRight
}

class NowPlayingPageController: UIViewController, UIPageViewControllerDelegate, UIPageViewControllerDataSource {
    
    let initialViewController: UIViewController
    let pageController: UIPageViewController
    var isAnimating: Bool
    var currentDate: NSDate? = NSDate()
    
    var currentViewController: UIViewController?
    
    init(viewController: UIViewController?) {
        initialViewController = viewController!
        currentViewController = viewController!
        isAnimating = false
    
        pageController = UIPageViewController(transitionStyle: .Scroll,
            navigationOrientation: .Horizontal,
            options: nil)
        pageController.setViewControllers([initialViewController],
            direction: .Forward,
            animated: false,
            completion: nil)
        
        super.init(nibName: nil, bundle: nil)
        
        pageController.delegate = self
        pageController.dataSource = self
    }
    
    override func viewDidLoad() {
        self.addChildViewController(pageController)
        pageController.didMoveToParentViewController(self)
        self.view.addSubview(pageController.view)
    }   

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {
        var previousVC = viewController as! RootViewController
        return previousVC
    }
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
        var nextVC = viewController as! RootViewController
        return nextVC
    }
    
}
