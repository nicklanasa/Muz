//
//  OverlayController.swift
//  Muz
//
//  Created by Nick Lanasa on 12/19/14.
//  Copyright (c) 2014 Nytek Productions. All rights reserved.
//

import Foundation
import UIkit

class OverlayController: UIViewController {
    @IBOutlet weak var backgroundImageView: UIImageView!
    
    var screenShot: UIImage!
    
    var overlayScreenName: NSString! {
        didSet {
            self.navigationItem.title = overlayScreenName
        }
    }
    
    override func viewDidLoad() {
        backgroundImageView.image = self.screenShot.applyDarkEffect()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        LocalyticsSession.shared().tagScreen(overlayScreenName)
    }
}