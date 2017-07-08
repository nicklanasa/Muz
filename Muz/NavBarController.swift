//
//  NavBarController.swift
//  Muz
//
//  Created by Nick Lanasa on 12/9/14.
//  Copyright (c) 2014 Nytek Productions. All rights reserved.
//

import Foundation
import UIKit

class NavBarController: UINavigationController {
    override func viewDidLoad() {
        // Add transparency.
        let rect = CGRect(x: 0, y: 0, width: 1, height: 1)
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 1.0);
        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(UIColor.clear.cgColor)
        context?.fill(rect)
        let transparentImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        self.navigationBar.setBackgroundImage(transparentImage, for: .default)
        self.navigationBar.shadowImage = transparentImage
        self.navigationBar.tintColor = UIColor.white
        self.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: MuzColor, NSFontAttributeName: MuzTitleFont]
        self.navigationItem.backBarButtonItem = UIBarButtonItem(image: UIImage(named: "back"), style: .plain, target: self, action: "")
    }
}
