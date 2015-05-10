//
//  SongsController.swift
//  Muz
//
//  Created by Nick Lanasa on 4/26/15.
//  Copyright (c) 2015 Nytek Productions. All rights reserved.
//

import WatchKit
import Foundation
import MediaPlayer

class SongsController: WKInterfaceController {
    
    @IBOutlet weak var table: WKInterfaceTable!
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
        var songQuery = MPMediaQuery.songsQuery()
        
        self.table.setNumberOfRows(songQuery.items.count, withRowType: "LabelCell")
        var i = 0
        for i in 0..<songQuery.items.count {
            if let row = self.table.rowControllerAtIndex(i) as? LabelCell {
                row.textLabel.setText("Current Date")
                var item = songQuery.items[i] as! MPMediaItem
                row.textLabel.setText(item.title)
            }
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