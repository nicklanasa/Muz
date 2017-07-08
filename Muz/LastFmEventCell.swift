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
        bringSubview(toFront: collectionView)
    }
    
    func updateWithEvents(_ lastFmEvents: [AnyObject]?) {
        
        if let _ = lastFmEvents {
            UIView.animate(withDuration: 0.3, animations: { () -> Void in
                self.upcomingEventsLabel.alpha = 1.0
                
                }, completion: { (success) -> Void in
                    if success {
                        self.collectionView.reloadData()
                    }
            }) 
        }
    }
    
    override func layoutSubviews() {
        if upcomingEventsLabel.isHidden {
            var collectionViewFrame = self.collectionView.frame
            collectionViewFrame.origin.y = 13
            self.collectionView.frame = collectionViewFrame
        }
    }

    override func prepareForReuse() {
    }
}
