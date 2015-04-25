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
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.syncButton.applyRoundedStyle()
    }
    
    @IBAction func syncButtonPressed(sender: AnyObject) {
        var error: NSError?
        
        self.syncButton.hidden = true
        self.syncLibraryLabel.hidden = true
        self.detailedLabel.hidden = true
        self.progressView.hidden = false
        
        let startTime = NSDate()
        
        self.syncButton.setTitle("", forState: .Normal)
        
        DataManager.manager.syncArtists({ (addedItems, error) -> () in
            
            let endTime = NSDate()
            let executionTime = endTime.timeIntervalSinceDate(startTime)
            NSLog("syncLibrary() - executionTime = %f\n", (executionTime * 1000));
            
            NSUserDefaults.standardUserDefaults().setObject(NSNumber(bool: true),
                forKey: "SyncLibrary")
            
            self.dismissViewControllerAnimated(true, completion: { () -> Void in
                DataManager.manager.syncPlaylists({ (addedItems, error) -> () in
                    LocalyticsSession.shared().tagEvent("Sync Library")
                })
            })

            }, progress: { (addedItems, total) -> () in
                self.syncedItems = addedItems
                if self.syncedItems?.count > 0 {
                    if let artist = self.syncedItems?[self.syncedItems!.count-1] as? Artist {
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            self.imageView.setImageForArtist(artist: artist)
                            self.progressView.progress = Float(self.syncedItems!.count) / Float(total)
                        })
                    }
                }
        })
    }
}