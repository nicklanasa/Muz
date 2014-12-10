//
//  AlbumsViewController.swift
//  Muz
//
//  Created by Nick Lanasa on 12/7/14.
//
//

import Foundation
import UIKit
import CoreData

class LovedViewController: RootViewController,
UITableViewDelegate,
UITableViewDataSource,
NSFetchedResultsControllerDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    // The NSFetchedResultsController used to pull tasks for the selected date.
    var loved: [AnyObject]?
    var lovedController: NSFetchedResultsController!
    
    override init() {
        super.init(nibName: "LovedViewController", bundle: nil)
        
        self.tabBarItem = UITabBarItem(title: "Loved",
            image: UIImage(named: "loved"),
            selectedImage: UIImage(named: "loved"))
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let tableView = self.tableView {
            tableView.registerNib(UINib(nibName: "ArtistCell", bundle: nil), forCellReuseIdentifier: "Cell")
        }
        
        fetchLoved()
                
        self.navigationItem.title = "Loved"
    }
    
    func fetchLoved() {
        
        lovedController = MediaSession.sharedSession.dataManager.datastore.lovedControllerWithSortKey("title",
            ascending: true,
            sectionNameKeyPath: nil)
        
        var error: NSError?
        if lovedController.performFetch(&error) {
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.tableView.reloadData()
                self.activityIndicator.stopAnimating()
            })
        }
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return lovedController.sections?.count ?? 0
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionInfo = lovedController.sections![section] as NSFetchedResultsSectionInfo
        return sectionInfo.numberOfObjects
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell",
            forIndexPath: indexPath) as ArtistCell
        let song = lovedController.objectAtIndexPath(indexPath) as Song
        cell.artistLabel.text = song.title
        return cell
    }
}
