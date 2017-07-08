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
    
    func updateWithEvent(_ event: LastFmEvent) {
        artistImageView.sd_setImage(with: event.image, placeholderImage: UIImage(named: "nowPlayingDefault"))
        
        if let _ = event.startDate {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            let date = formatter.string(from: event.startDate)
            
            infoLabel.text = String(format: "%@\n%@\n%@", event.city, event.country, date)
        }
    }
    
    func updateWithGeoEvent(_ event: LastFmEvent) {
        artistImageView.sd_setImage(with: event.image, placeholderImage: UIImage(named: "nowPlayingDefault"))
        
        if let _ = event.title {
            infoLabel.text = String(format: "%@\n%@\n%@", event.title, event.city, event.country)
        }
    }
    
    override func prepareForReuse() {

    }
}
