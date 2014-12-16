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
    @IBOutlet weak var bioLabel: UILabel!
    @IBOutlet weak var playsDescriptionLabel: UILabel!
    @IBOutlet weak var listenersDescriptionLabel: UILabel!
    
    override func awakeFromNib() {
        bringSubviewToFront(collectionView)
        
        artistImageView.layer.cornerRadius = artistImageView.frame.size.height / 2
        artistImageView.layer.masksToBounds = true
    }
    
    func updateWithArtist(lastFmArtist: LastFmArtist?) {
        
        activityIndicator.stopAnimating()
        
        if let artist = lastFmArtist {
            UIView.animateWithDuration(0.3, animations: { () -> Void in
                self.artistLabel.alpha = 1.0
                self.listenersLabel.alpha = 1.0
                self.playsLabel.alpha = 1.0
                self.playsLabel.alpha = 1.0
                self.bioTextView.alpha = 1.0
                self.bioLabel.alpha = 1.0
                self.listenersDescriptionLabel.alpha = 1.0
                self.playsDescriptionLabel.alpha = 1.0
                
                self.artistImageView.sd_setImageWithURL(artist.imageURL)
                }) { (success) -> Void in
                    if success {
                        var numberFormatter = NSNumberFormatter()
                        numberFormatter.numberStyle = .DecimalStyle
                        
                        let plays = artist.plays ?? 0
                        let listeners = artist.listeners ?? 0
                        
                        self.artistLabel.text = artist.name
                        self.listenersLabel.text = NSString(format: "%@", numberFormatter.stringFromNumber(listeners)!)
                        self.playsLabel.text = NSString(format: "%@", numberFormatter.stringFromNumber(plays)!)
                        self.bioTextView.text = artist.bio
                        
                        self.artistImageView.sd_setImageWithURL(artist.imageURL)
                        
                        self.collectionView.reloadData()
                    }
            }
        }
    }

    override func prepareForReuse() {
        activityIndicator.startAnimating()
    }
}