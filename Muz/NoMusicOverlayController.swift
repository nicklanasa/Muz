//
//  NoMusicOverlayController.swift
//  Muz
//
//  Created by Nick Lanasa on 12/28/14.
//  Copyright (c) 2014 Nytek Productions. All rights reserved.
//

import Foundation
import UIKit

class NoMusicOverlayController: UIViewController {
    
    override init() {
        super.init(nibName: "NoMusicOverlayController", bundle: nil)
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @IBAction func openItunesButtonTapped(sender: AnyObject) {
        UIApplication.sharedApplication().openURL(NSURL(string: "https://itunes.apple.com/us/music/")!)
    }
    
    override func viewDidLoad() {
        self.view.autoresizingMask = .FlexibleWidth | .FlexibleHeight
        self.view.frame = UIScreen.mainScreen().bounds
    }
}