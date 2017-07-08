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
    
    @IBOutlet weak var noMusicLabel: UILabel!
    init() {
        super.init(nibName: "NoMusicOverlayController", bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @IBAction func openItunesButtonTapped(_ sender: AnyObject) {
        UIApplication.shared.openURL(URL(string: "https://itunes.apple.com/us/music/")!)
    }
    
    override func viewDidLoad() {
        self.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.view.frame = UIScreen.main.bounds
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            self.noMusicLabel.text = "Your music library is empty. Please add music to your iPad."
        } else {
            self.noMusicLabel.text = "Your music library is empty. Please add music to your iPhone."
        }
    }
}
