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
    @IBOutlet weak var linkButton: UIButton!
    @IBOutlet weak var headLinerLabel: UILabel!
    @IBOutlet weak var artistImageView: UIImageView!
    @IBOutlet weak var descriptionTextView: UITextView!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var attendenceLabel: UILabel!
    
    var event: LastFmEvent!
    
    override func awakeFromNib() {
        artistImageView.layer.cornerRadius = artistImageView.frame.size.height / 2
        artistImageView.layer.masksToBounds = true
        
        self.linkButton.layer.borderColor = UIColor.whiteColor().CGColor
        self.linkButton.layer.borderWidth = 1
        self.linkButton.layer.cornerRadius = 5
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
        
        var request = MKLocalSearchRequest()
        request.naturalLanguageQuery = NSString(format: "%@ %@, %@", event.venue, event.city, event.country)

        let search = MKLocalSearch(request: request)
        
        var matchedItems = NSMutableArray()
        var annotations = NSMutableArray()
        
        search.startWithCompletionHandler { (response, error) -> Void in
            if error == nil {
                if response.mapItems.count == 0 {
                    
                } else {
                    for item in response.mapItems as [MKMapItem] {
                        matchedItems.addObject(item)
                        
                        var point = MKPointAnnotation()
                        point.coordinate = item.placemark.coordinate
                        point.title = item.name
                        self.mapView.addAnnotation(point)
                        
                        annotations.addObject(point)
                    }
                    
                    self.mapView.showAnnotations(annotations, animated: true)
                }
            }
        }
    }
}