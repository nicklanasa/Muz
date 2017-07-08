//
//  SyncController.swift
//  Muz
//
//  Created by Nick Lanasa on 2/5/15.
//  Copyright (c) 2015 Nytek Productions. All rights reserved.
//

import Foundation
import UIKit
import CoreData
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


class SyncOverlayController: OverlayController {
    @IBOutlet weak var syncButton: UIButton!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var detailedLabel: UILabel!
    @IBOutlet weak var syncLibraryLabel: UILabel!
    
    var syncedItems: [AnyObject]?
        
    init() {
        super.init(nibName: "SyncOverlayController", bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.syncButton.applyRoundedStyle()
    }
    
    @IBAction func syncButtonPressed(_ sender: AnyObject) {
        
        self.syncButton.isHidden = true
        self.syncLibraryLabel.isHidden = true
        self.detailedLabel.isHidden = true
        self.progressView.isHidden = false
        
        let startTime = Date()
        
        self.syncButton.setTitle("", for: UIControlState())
        
        DataManager.manager.syncArtists({ (addedItems, error) -> () in
            
            let endTime = Date()
            let executionTime = endTime.timeIntervalSince(startTime)
            NSLog("syncLibrary() - executionTime = %f\n", (executionTime * 1000));
            
            UserDefaults.standard.set(NSNumber(value: true as Bool),
                forKey: "SyncLibrary")
            
            self.dismiss(animated: true, completion: { () -> Void in
                DataManager.manager.syncPlaylists({ (addedItems, error) -> () in
                })
            })

            }, progress: { (addedItems, total) -> () in
                self.syncedItems = addedItems
                if self.syncedItems?.count > 0 {
                    if let artist = self.syncedItems?[self.syncedItems!.count-1] as? Artist {
                        DispatchQueue.main.async(execute: { () -> Void in
                            self.imageView.setImageForArtist(artist: artist)
                            self.progressView.progress = Float(self.syncedItems!.count) / Float(total)
                        })
                    }
                }
        })
    }
}
