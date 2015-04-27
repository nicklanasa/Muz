//
//  NowPlayingInterfaceController.swift
//  Muz
//
//  Created by Nick Lanasa on 4/26/15.
//  Copyright (c) 2015 Nytek Productions. All rights reserved.
//

import WatchKit
import Foundation
import MediaPlayer

class NowPlayingInterfaceController: WKInterfaceController {
    
    @IBOutlet weak var nowPlayingButton: WKInterfaceButton!
    @IBOutlet weak var nowPlayingLabel: WKInterfaceLabel!
    
    @IBAction func nowPlayingButtonImageTapped() {
        WKInterfaceController.openParentApplication(["action": "pausePlay"], reply: { (result, error) -> Void in
            if result != nil {
                if let image = result["nowPlayingArtwork"] as? UIImage {
                    self.nowPlayingButton.setBackgroundImage(image)
                }
            }
        })
    }
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        self.updateNowPlayingButton()
  
        WKNotificationCenter.defaultCenterWithGroupIndentifier("group.muz").addObserverWithIdentifier("nowPlayingArtwork",
            observer: self,
            selector: "updateNowPlayingButton", object: nil)
    }
    
    func updateNowPlayingButton() {
        if let item = MPMusicPlayerController.iPodMusicPlayer().nowPlayingItem {
            var image = item.artwork.imageWithSize(CGSizeMake(200, 200))
            self.nowPlayingButton.setBackgroundImage(image)
            
            self.nowPlayingLabel.setText("\(item.artist) - \(item.title)")
        }
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
}
