//
//  ArtistsViewController.swift
//  Muz
//
//  Created by Nick Lanasa on 12/7/14.
//
//

import Foundation
import UIKit
import CoreData

class ArtistsViewController: UIViewController,
UITableViewDelegate,
UITableViewDataSource,
NSFetchedResultsControllerDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    // The NSFetchedResultsController used to pull tasks for the selected date.
    var artists: [AnyObject]?
    
    override init() {
        super.init(nibName: "ArtistsViewController", bundle: nil)
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        tableView.registerNib(UINib(nibName: "ArtistCell", bundle: nil), forCellReuseIdentifier: "Cell")
        tableView.alpha = 0.0
        
        MusicSession.sharedSession.openSessionWithCompletionBlock { (success) -> () in
            self.fetchArtists()
        }
        
        self.title = "Artists"
    }
    
    func fetchArtists() {
        self.artists = MusicSession.sharedSession.dataManager.datastore.artistsWithSortKey("artist",
            ascending: true,
            sectionNameKeyPath: nil)
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.tableView.alpha = 1.0
            self.tableView.reloadData()
            self.activityIndicator.stopAnimating()
        })

    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if artists?.count > 0 {
            return artists!.count
        }
        
        return 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell",
            forIndexPath: indexPath) as ArtistCell
        let artist = artists![indexPath.row] as NSDictionary
        cell.artistLabel.text = artist.objectForKey("artist") as NSString
        return cell
    }
}
