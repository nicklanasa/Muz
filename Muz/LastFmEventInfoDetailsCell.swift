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

protocol LastFmEventInfoDetailsCellDelegate {
    func lastFmEventInfoDetailsCell(cell: LastFmEventInfoDetailsCell, didTapViewMapButton sender: AnyObject)
}

class LastFmEventInfoDetailsCell: UITableViewCell {
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var linkButton: UIButton!
    @IBOutlet weak var headLinerLabel: UILabel!
    @IBOutlet weak var artistImageView: UIImageView!
    @IBOutlet weak var descriptionTextView: UITextView!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var attendenceLabel: UILabel!
    @IBOutlet weak var viewMapButton: UIButton!
    
    var delegate: LastFmEventInfoDetailsCellDelegate?
    
    var event: LastFmEvent!
    
    override func awakeFromNib() {
        artistImageView.layer.cornerRadius = artistImageView.frame.size.height / 2
        artistImageView.layer.masksToBounds = true
        
        self.linkButton.layer.borderColor = UIColor.whiteColor().CGColor
        self.linkButton.layer.borderWidth = 1
        self.linkButton.layer.cornerRadius = 5
        
        self.viewMapButton.layer.borderColor = UIColor.whiteColor().CGColor
        self.viewMapButton.layer.borderWidth = 1
        self.viewMapButton.layer.cornerRadius = 5
    }
    
    @IBAction func viewMapButtonTapped(sender: AnyObject) {
        delegate?.lastFmEventInfoDetailsCell(self, didTapViewMapButton: sender)
    }
    
    @IBAction func linkButtonTapped(sender: AnyObject) {
        UIApplication.sharedApplication().openURL(event.url)
    }
    
    func updateWithEvent(event: LastFmEvent) {
        self.event = event
        self.headLinerLabel.text = NSString(format: "Headliner: %@", event.headliner)
        self.attendenceLabel.text = NSString(format: "Attendence: %d", event.attendance.integerValue)
        self.artistImageView.sd_setImageWithURL(event.image)
        self.descriptionTextView.text = event.eventDescription
        
        let formatter = NSDateFormatter()
        formatter.dateStyle = .ShortStyle
        let date = formatter.stringFromDate(event.startDate)
        
        titleLabel.text = event.title
        dateLabel.text = date
        
        locationLabel.text = NSString(format: "%@, %@", event.city, event.country)
        
    }
}