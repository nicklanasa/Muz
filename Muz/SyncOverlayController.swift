//
//  SyncController.swift
//  Muz
//
//  Created by Nick Lanasa on 2/5/15.
//  Copyright (c) 2015 Nytek Productions. All rights reserved.
//

import Foundation
import UIKit
import CoreData

class SyncOverlayController: OverlayController,
UICollectionViewDataSource,
NSFetchedResultsControllerDelegate {
    @IBOutlet weak var syncButton: UIButton!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var progressLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var scrollTimer: NSTimer!
    
    var endPoint: CGPoint! {
        get {
            return CGPoint(x: self.collectionView.contentSize.width,
                y: self.collectionView.contentSize.height)
        }
    }
    
    var currentPoint: CGPoint = CGPoint(x: 0, y: 0)
    
    lazy var songsController: NSFetchedResultsController = {
        let controller = DataManager.manager.datastore.songsControllerWithSortKey("artist",
            ascending: true,
            sectionNameKeyPath: "artist.stringByGroupingByFirstLetter")
        controller.delegate = self
        return controller
    }()
    
    override init() {
        super.init(nibName: "SyncOverlayController", bundle: nil)
    }
    
    required override init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.syncButton.applyRoundedStyle()
        
        let nib = UINib(nibName: "SimiliarArtistCollectionViewCell", bundle: nil)
        collectionView.registerNib(nib, forCellWithReuseIdentifier: "ArtistCell")
        
        self.scrollTimer = NSTimer.scheduledTimerWithTimeInterval(1,
            target: self,
            selector: "scrollCollectionView",
            userInfo: nil,
            repeats: true)
    }
    
    func scrollCollectionView() {
        UIView.animateWithDuration(0.1, animations: { () -> Void in
            self.collectionView.contentOffset = self.currentPoint
            
            if CGPointEqualToPoint(self.currentPoint, self.endPoint) {
                self.scrollTimer.invalidate()
            }
            
            self.currentPoint = CGPointMake(self.currentPoint.x+10, self.currentPoint.y)
        })	
    }
    
    @IBAction func syncButtonPressed(sender: AnyObject) {
        var error: NSError?
        
        let startTime = NSDate()
        
        self.syncButton.setTitle("", forState: .Normal)
        
        self.progressLabel.text = "Syncing library..."
        
        self.activityIndicator.startAnimating()
        
        if self.songsController.performFetch(&error) {
            DataManager.manager.syncArtists({ (addedItems, error) -> () in
                
                self.activityIndicator.stopAnimating()
                
                let endTime = NSDate()
                let executionTime = endTime.timeIntervalSinceDate(startTime)
                NSLog("syncLibrary() - executionTime = %f\n", (executionTime * 1000));
                
                LocalyticsSession.shared().tagEvent("Sync Library")
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    NSUserDefaults.standardUserDefaults().setObject(NSNumber(bool: true),
                        forKey: "SyncLibrary")
                    self.dismissViewControllerAnimated(true, completion: nil)
                })
            })
        }
    }
    
    // MARK: Sectors NSFetchedResultsControllerDelegate
    
    func controllerWillChangeContent(controller: NSFetchedResultsController)
    {
        
    }
    
    func controller(controller: NSFetchedResultsController,
        didChangeObject anObject: AnyObject,
        atIndexPath indexPath: NSIndexPath?,
        forChangeType type: NSFetchedResultsChangeType,
        newIndexPath: NSIndexPath?)
    {

    }
    
    func controller(controller: NSFetchedResultsController,
        didChangeSection sectionInfo: NSFetchedResultsSectionInfo,
        atIndex sectionIndex: Int,
        forChangeType type: NSFetchedResultsChangeType)
    {

    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController)
    {
//        self.collectionView.reloadData()
//        self.progressLabel.text = self.collectionView.numberOfItemsInSection(0).description
//        var bottomRightPoint = CGPointMake(UIScreen.mainScreen().bounds.size.width, UIScreen.mainScreen().bounds.size.height)
//        if let indexPath = self.collectionView.indexPathForItemAtPoint(bottomRightPoint) {
//            self.collectionView.scrollToItemAtIndexPath(indexPath,
//                atScrollPosition: .Right,
//                animated: true)
//        }
    }
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return self.songsController.sections?.count ?? 0
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let numberOfRowsInSection = self.songsController.sections?[section].numberOfObjects {
            return numberOfRowsInSection
        } else {
            return 0
        }
    }
    
    // The cell that is returned must be retrieved from a call to -dequeueReusableCellWithReuseIdentifier:forIndexPath:
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        var cell = collectionView.dequeueReusableCellWithReuseIdentifier("ArtistCell",
            forIndexPath: indexPath) as SimiliarArtistCollectionViewCell
        let song = self.songsController.objectAtIndexPath(indexPath) as Song
        cell.artistImageView.setImageForSong(song: song)
        cell.artistLabel.text = song.artist
        return cell
    }
}