//
//  LastFmEventMapController.swift
//  Muz
//
//  Created by Nick Lanasa on 12/23/14.
//  Copyright (c) 2014 Nytek Productions. All rights reserved.
//

import Foundation
import UIKit
import MapKit

class LastFmEventMapController: RootViewController {
    
    @IBOutlet weak var mapView: MKMapView!
    
    let event: LastFmEvent!
    
    var matchedItems = NSMutableArray()
    
    init(event: LastFmEvent) {
        self.event = event
        super.init(nibName: "LastFmEventMapController", bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadMap()
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Open in maps",
            style: .Plain,
            target: self,
            action: "openInMaps")
        
        self.title = event.venue
    }
    
    override func viewWillAppear(animated: Bool) {
        self.screenName = "Event map"
    }
    
    func openInMaps() {
        for item in matchedItems {
            if let mapItem = item as? MKMapItem {
                mapItem.openInMapsWithLaunchOptions(nil)
                break;
            }
        }
    }
    
    private func loadMap() {
        let request = MKLocalSearchRequest()
        request.naturalLanguageQuery = String(format: "%@ %@, %@", event.venue, event.city, event.country)
        
        let search = MKLocalSearch(request: request)
        var annotations = [AnyObject]()
        
        search.startWithCompletionHandler { (response, error) -> Void in
            if error == nil {
                if response?.mapItems.count == 0 {
                    
                } else {
                    for item in response!.mapItems {
                        self.matchedItems.addObject(item)
                        
                        let point = MKPointAnnotation()
                        point.coordinate = item.placemark.coordinate
                        point.title = item.name
                        self.mapView.addAnnotation(point)
                        
                        annotations.append(point)
                    }
                    
                    self.mapView.showAnnotations(annotations as! [MKAnnotation], animated: true)
                }
            }
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
    }
}