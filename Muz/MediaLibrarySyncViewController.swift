//
//  MediaLibrarySyncViewController.swift
//  Muz
//
//  Created by Nick Lanasa on 12/12/14.
//  Copyright (c) 2014 Nytek Productions. All rights reserved.
//

import Foundation
import UIKit
import CoreData
import MediaPlayer

class MediaLibrarySyncViewController: RootViewController {

    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var songLabel: UILabel!
    @IBOutlet weak var syncButton: UIButton!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    override init() {
        super.init(nibName: "MediaLibrarySyncViewController", bundle: nil)
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        syncButton.layer.cornerRadius = 2
        syncButton.layer.masksToBounds = true
    }
    
    @IBAction func syncButtonTapped(sender: AnyObject) {
        syncButton.enabled = false
        MediaSession.sharedSession.openSessionWithUpdateBlock { (percentage, error, song) -> () in
            
            
            if error != nil {
                let alert = UIAlertController(title: "Error!", message: "Unable to sync library!", preferredStyle: .Alert)
                self.presentViewController(alert, animated: true, completion: { () -> Void in
                    
                })
                
            } else {
                self.updateViewWithPercentage(percentage, song: song)
            }
        }
    }
    
    private func updateViewWithPercentage(percentage: Float, song: Song?) {
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            
            UIView.animateWithDuration(0.3, animations: { () -> Void in
                self.syncButton.alpha = 0.0
                self.imageView.alpha = 1.0
                self.songLabel.alpha = 1.0
                self.progressView.alpha = 1.0
                self.activityIndicator.alpha = 1.0
                
            }, completion: { (success) -> Void in
                self.progressView.progress = percentage
                
                if let s = song {
                    
                    UIView.animateWithDuration(0.3, animations: { () -> Void in
                        
                        /*
                        if let image = UIImage(data: s.artwork) {
                            self.imageView.image = image
                        }
                        
                        self.songLabel.text = song?.title
                        */
                        self.songLabel.text = NSString(format: "%.0f%%", percentage * 100)
                    })
                } else {
                    self.songLabel.text = "Finishing up..."
                }
                
                if percentage >= 100 {
                    
                    self.dismissViewControllerAnimated(true, completion: { () -> Void in
                        
                    })
                }
            })
        })
    }

}