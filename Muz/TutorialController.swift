//
//  TutorialController.swift
//  Muz
//
//  Created by Nick Lanasa on 12/28/14.
//  Copyright (c) 2014 Nytek Productions. All rights reserved.
//

import Foundation
import UIKit

class TutorialController: UIViewController {
    
    init() {
        super.init(nibName: "TutorialController", bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        self.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }
}
