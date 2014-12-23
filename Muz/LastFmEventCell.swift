//
//  LastFmEventCell.swift
//  Muz
//
//  Created by Nick Lanasa on 12/14/14.
//  Copyright (c) 2014 Nytek Productions. All rights reserved.
//

import Foundation
import UIKit
import MediaPlayer

class LastFmEventCell: UITableViewCell {
    
    var cellHeight: CGFloat = 170.0

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var upcomingEventsLabel: UILabel!
    
    override func awakeFromNib() {
        bringSubviewToFront(collectionView)
    }
    
    func updateWithEvents(lastFmEvents: [AnyObject]?) {
        
        if let events = lastFmEvents {
            UIView.animateWithDuration(0.3, animations: { () -> Void in
                self.upcomingEventsLabel.alpha = 1.0
                
                }) { (success) -> Void in
                    if success {
                        self.collectionView.reloadData()
                    }
            }
        }
    }

    override func prepareForReuse() {
    }
}