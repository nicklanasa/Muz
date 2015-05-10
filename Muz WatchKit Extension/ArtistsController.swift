//
//  ArtistsController.swift
//  Muz
//
//  Created by Nick Lanasa on 4/26/15.
//  Copyright (c) 2015 Nytek Productions. All rights reserved.
//

import WatchKit
import Foundation
import MediaPlayer

class AristsController: WKInterfaceController {
    
    @IBOutlet weak var table: WKInterfaceTable!

    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
        var artistQuery = MPMediaQuery.artistsQuery()
        print(artistQuery.items.count)
        self.table.setNumberOfRows(artistQuery.items.count, withRowType: "LabelCell")
        
        for (i, item) in enumerate(artistQuery.items) {
            if let row = self.table.rowControllerAtIndex(i) as? LabelCell {
                row.textLabel.setText(item.artist)
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