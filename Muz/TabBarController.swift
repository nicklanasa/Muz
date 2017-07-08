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
    case artists
    case songs
    case nowPlaying
    case playlists
    case more
}

class TabBarController: UITabBarController {
    override func viewDidLoad() {
        
        // Add transparency.
        let rect = CGRect(x: 0, y: 0, width: 1, height: 1)
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 1.0);
        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(UIColor.clear.cgColor)
        context?.fill(rect)
        let transparentImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        self.tabBar.backgroundImage = transparentImage
        self.tabBar.shadowImage = transparentImage
        self.tabBar.tintColor = MuzBlueColor
    }
}
