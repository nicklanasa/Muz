//
//  TabBarController.swift
//  Muz
//
//  Created by Nick Lanasa on 12/9/14.
//  Copyright (c) 2014 Nytek Productions. All rights reserved.
//

import Foundation
import UIKit

enum TabBarItem: NSInteger {
    case Artists
    case Songs
    case NowPlaying
    case Playlists
    case More
}

class TabBarController: UITabBarController {
    override func viewDidLoad() {
        
        // Add transparency.
        let rect = CGRectMake(0, 0, 1, 1)
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 1.0);
        let context = UIGraphicsGetCurrentContext()
        CGContextSetFillColorWithColor(context, UIColor.clearColor().CGColor)
        CGContextFillRect(context, rect)
        let transparentImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        self.tabBar.backgroundImage = transparentImage
        self.tabBar.shadowImage = transparentImage
        self.tabBar.tintColor = MuzBlueColor
    }
}
