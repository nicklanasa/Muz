//
//  NowPlayingCollectionController.swift
//  Muz
//
//  Created by Nick Lanasa on 12/18/14.
//  Copyright (c) 2014 Nytek Productions. All rights reserved.
//

import Foundation
import UIKit
import MediaPlayer

protocol NowPlayingCollectionControllerDelegate {
    func nowPlayingCollectionController(controller: NowPlayingCollectionController, didSelectItem item: MPMediaItem)
}

class NowPlayingCollectionController: OverlayController,
UITableViewDelegate,
UITableViewDataSource {
    
    private var currentlyPlayingCollection: MPMediaItemCollection?
    
    var delegate: NowPlayingCollectionControllerDelegate?
    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    
    init(collection: MPMediaItemCollection?) {
        super.init(nibName: "NowPlayingCollectionController", bundle: nil)
        self.currentlyPlayingCollection = collection
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        tableView.registerNib(UINib(nibName: "SongCell", bundle: nil), forCellReuseIdentifier: "Cell")
        tableView.registerNib(UINib(nibName: "ArtistAlbumHeader", bundle: nil), forHeaderFooterViewReuseIdentifier: "Header")
        
        tableView.reloadData()
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "back"),
            style: .Plain,
            target: self,
            action: "dismiss")
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.overlayScreenName = "Songs"
    }
    
    func dismiss() {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return currentlyPlayingCollection?.items.count ?? 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell",
            forIndexPath: indexPath) as! SongCell
        
        if let item = currentlyPlayingCollection?.items[indexPath.row] {
            cell.updateWithItem(item)
            cell.accessoryType = .DetailDisclosureButton
        }
        
        return cell
    }

    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        // Get song.
        if let song = currentlyPlayingCollection?.items[indexPath.row]{
            delegate?.nowPlayingCollectionController(self, didSelectItem: song)
            dismissViewControllerAnimated(true, completion: nil)
        }
        
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
}