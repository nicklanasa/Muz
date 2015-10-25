//
//  LastFmEventInfoDetailsCell.swift
//  Muz
//
//  Created by Nick Lanasa on 12/20/14.
//  Copyright (c) 2014 Nytek Productions. All rights reserved.
//

import Foundation
import UIKit
import MapKit

class LastFmEventInfoDetailsCell: UITableViewCell {
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var headLinerLabel: UILabel!
    @IBOutlet weak var artistImageView: UIImageView!
    @IBOutlet weak var descriptionTextView: UITextView!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var attendenceLabel: UILabel!
    @IBOutlet weak var headLinerValueLabel: UILabel!
    @IBOutlet weak var attendenceValueLabel: UILabel!
    
    var event: LastFmEvent!
    
    func updateWithEvent(event: LastFmEvent) {
        self.event = event
        self.headLinerValueLabel.text = event.headliner
        self.attendenceValueLabel.text = event.attendance.integerValue.abbreviateNumber()
        self.artistImageView.sd_setImageWithURL(event.image, placeholderImage: UIImage(named: "nowPlayingDefault"))
        self.descriptionTextView.text = event.eventDescription
        
        if event.eventDescription.characters.count == 0 {
            self.descriptionTextView.text = "Description unavailable"
        }
        
        let formatter = NSDateFormatter()
        formatter.dateStyle = .ShortStyle
        let date = formatter.stringFromDate(event.startDate)
        
        self.titleLabel.text = event.title
        self.dateLabel.text = date
        
        self.locationLabel.text = String(format: "%@, %@", event.city, event.country)
        
    }
}