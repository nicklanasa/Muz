//
//  TopAlbumsViewController.swift
//  Muz
//
//  Created by Nick Lanasa on 2/9/15.
//  Copyright (c) 2015 Nytek Productions. All rights reserved.
//

import Foundation
import UIKit

class TopAlbumsViewController: RootViewController, LastFmAlbumBuyLinksRequestDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    let topAlbums: [AnyObject]!
    
    var actionSheet: LastFmBuyLinksViewController!
    var albumBuyLinks: [AnyObject]! {
        didSet {
            
        }
    }
    
    init(topAlbums: [AnyObject]) {
        super.init(nibName: "TopAlbumsViewController", bundle: nil)
        self.topAlbums = topAlbums
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.registerNib(UINib(nibName: "TopAlbumCell", bundle: nil), forCellReuseIdentifier: "TopAlbumCell")
        
        self.navigationItem.title = "Top Albums"
    }
    
    override func viewWillAppear(animated: Bool) {
        self.screenName = "Top Albums"
        super.viewWillAppear(animated)
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.topAlbums.count
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("TopAlbumCell",
            forIndexPath: indexPath) as TopAlbumCell
        
        let topAlbum = self.topAlbums[indexPath.row] as LastFmAlbum
        cell.songLabel.text = topAlbum.title
        cell.infoLabel.text = topAlbum.artist
        if let image = topAlbum.image {
            cell.songImageView.sd_setImageWithURL(NSURL(string: image))
        } else {
            cell.songImageView.image = UIImage(named: "nowPlayingDefault")
        }
        
        
        cell.buyButton.hidden = false
        
        cell.selectionStyle = .None
        
        cell.buyButton.addTarget(self, action: "fetchBuyLinks:", forControlEvents: .TouchUpInside)
        cell.buyButton.tag = indexPath.row
        
        return cell
    }
    
    func fetchBuyLinks(sender: AnyObject?) {
        if let button = sender as? UIButton {
            print("Button tag: \(button.tag)\n")
            print("fetching buy links for top albums...")
            
            let topAlbum = self.topAlbums[button.tag] as LastFmAlbum
            
            var lastFmAlbumBuyLinksRequest = LastFmAlbumBuyLinksRequest(artist: topAlbum.artist, album: topAlbum.title)
            lastFmAlbumBuyLinksRequest.delegate = self
            lastFmAlbumBuyLinksRequest.sendURLRequest()
        }
    }
    
    func lastFmAlbumBuyLinksRequestDidComplete(request: LastFmAlbumBuyLinksRequest, didCompleteWithBuyLinks buyLinks: [AnyObject]?) {
        self.albumBuyLinks = buyLinks
        
        if let buyLinks = albumBuyLinks {
            actionSheet = LastFmBuyLinksViewController(buyLinks: buyLinks)
        
            if actionSheet.numberOfValidBuyLinks == 0 {
               showBuyAlbumError()
            } else {
                actionSheet.showInView(self.view)
            }
        } else {
            showBuyAlbumError()
        }

    }
    
    private func showBuyAlbumError() {
        UIAlertView(title: "Error!",
            message: "Unable to find buy links for that album.",
            delegate: self,
            cancelButtonTitle: "Ok").show();
    }
}