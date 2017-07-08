//
//  OverlayController.swift
//  Muz
//
//  Created by Nick Lanasa on 12/19/14.
//  Copyright (c) 2014 Nytek Productions. All rights reserved.
//

import Foundation
import UIKit

class OverlayController: UIViewController {
    @IBOutlet weak var backgroundImageView: UIImageView!
    
    var screenShot: UIImage!
    
    var overlayScreenName: String! {
        didSet {
            self.navigationItem.title = self.overlayScreenName
        }
    }
    
    override func viewDidLoad() {
        self.backgroundImageView.image = self.screenShot.applyDarkEffect()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
}
