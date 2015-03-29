//
//  LastFmEventInfoCell.swift
//  Muz
//
//  Created by Nick Lanasa on 12/14/14.
//  Copyright (c) 2014 Nytek Productions. All rights reserved.
//

import Foundation
class LastFmEventInfoCell: UICollectionViewCell {
    
    @IBOutlet weak var artistImageView: UIImageView!
    @IBOutlet weak var infoLabel: UILabel!
    
    override func awakeFromNib() {
        artistImageView.layer.cornerRadius = 0
        artistImageView.layer.masksToBounds = true
    }
    
    func updateWithEvent(event: LastFmEvent) {
        artistImageView.sd_setImageWithURL(event.image, placeholderImage: UIImage(named: "nowPlayingDefault"))
        
        if let startDate = event.startDate {
            let formatter = NSDateFormatter()
            formatter.dateStyle = .ShortStyle
            let date = formatter.stringFromDate(event.startDate)
            
            infoLabel.text = NSString(format: "%@\n%@\n%@", event.city, event.country, date)
        }
    }
    
    func updateWithGeoEvent(event: LastFmEvent) {
        artistImageView.sd_setImageWithURL(event.image, placeholderImage: UIImage(named: "nowPlayingDefault"))
        
        if let title = event.title {
            infoLabel.text = NSString(format: "%@\n%@\n%@", event.title, event.city, event.country)
        }
    }
    
    override func prepareForReuse() {

    }
}