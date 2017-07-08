//
//  MonthPagingViewController.swift
//  Calendar-Month-View
//
//  Created by Nick Lanasa on 9/9/14.
//

import Foundation
import UIKit

enum SwipeDirection {
    case swipeDirectionLeft
    case swipeDirectionRight
}

class NowPlayingPageController: UIViewController, UIPageViewControllerDelegate, UIPageViewControllerDataSource {
    
    let initialViewController: UIViewController
    let pageController: UIPageViewController
    var isAnimating: Bool
    var currentDate: Date? = Date()
    
    var currentViewController: UIViewController?
    
    init(viewController: UIViewController?) {
        initialViewController = viewController!
        currentViewController = viewController!
        isAnimating = false
    
        pageController = UIPageViewController(transitionStyle: .scroll,
            navigationOrientation: .horizontal,
            options: nil)
        pageController.setViewControllers([initialViewController],
            direction: .forward,
            animated: false,
            completion: nil)
        
        super.init(nibName: nil, bundle: nil)
        
        pageController.delegate = self
        pageController.dataSource = self
    }
    
    override func viewDidLoad() {
        self.addChildViewController(pageController)
        pageController.didMove(toParentViewController: self)
        self.view.addSubview(pageController.view)
    }   

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        let previousVC = viewController as! RootViewController
        return previousVC
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        let nextVC = viewController as! RootViewController
        return nextVC
    }
    
}
