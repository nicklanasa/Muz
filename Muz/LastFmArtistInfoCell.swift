//
//  LastFmSongInfoCell.swift
//  Muz
//
//  Created by Nick Lanasa on 12/14/14.
//  Copyright (c) 2014 Nytek Productions. All rights reserved.
//

import Foundation
import UIKit
import MediaPlayer

let LastFmArtistInfoCellHeight: CGFloat = 669.0

class LastFmArtistInfoCell: UITableViewCell {
    
    @IBOutlet weak var artistLabel: UILabel!
    @IBOutlet weak var artistImageView: UIImageView!
    @IBOutlet weak var listenersLabel: UILabel!
    @IBOutlet weak var playsLabel: UILabel!
    @IBOutlet weak var bioTextView: UITextView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    override func awakeFromNib() {
        bringSubviewToFront(collectionView)
        
        artistImageView.layer.cornerRadius = artistImageView.frame.size.height / 2
        artistImageView.layer.masksToBounds = true
        artistImageView.layer.borderColor = UIColor.whiteColor().CGColor
        artistImageView.layer.borderWidth = 1
    }
    
    func updateWithArtist(lastFmArtist: LastFmArtist?) {
        
        activityIndicator.stopAnimating()
        
        UIView.animateWithDuration(0.3, animations: { () -> Void in
            self.artistLabel.alpha = 1.0
            self.listenersLabel.alpha = 1.0
            self.playsLabel.alpha = 1.0
            self.playsLabel.alpha = 1.0
            self.bioTextView.alpha = 1.0
            
            self.artistImageView.sd_setImageWithURL(lastFmArtist?.imageURL)
            }) { (success) -> Void in
                if success {
                    
                    var numberFormatter = NSNumberFormatter()
                    numberFormatter.numberStyle = .DecimalStyle
                    
                    let plays = lastFmArtist?.plays ?? 0
                    let listeners = lastFmArtist?.listeners ?? 0
                    
                    self.artistLabel.text = lastFmArtist?.name
                    self.listenersLabel.text = NSString(format: "%@", numberFormatter.stringFromNumber(listeners)!)
                    self.playsLabel.text = NSString(format: "%@", numberFormatter.stringFromNumber(plays)!)
                    self.bioTextView.text = lastFmArtist?.bio
                    
                    self.artistImageView.sd_setImageWithURL(lastFmArtist?.imageURL)
                }
        }
    }
    
    func updateWithSimiliarArtists(artists: [AnyObject]?) {
        
        UIView.animateWithDuration(0.3, animations: { () -> Void in
            self.collectionView.alpha = 1.0
            
        })
    }
    
    override func prepareForReuse() {
        activityIndicator.startAnimating()
    }
}