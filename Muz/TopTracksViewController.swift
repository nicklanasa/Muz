//
//  TopTracksViewController.swift
//  Muz
//
//  Created by Nick Lanasa on 2/9/15.
//  Copyright (c) 2015 Nytek Productions. All rights reserved.
//

import Foundation
import UIKit

class TopTracksViewController: RootViewController, LastFmTrackBuyLinksRequestDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    let topTracks: [AnyObject]!
    let artist: NSString!
    
    var actionSheet: LastFmBuyLinksViewController!
    var songBuyLinks: [AnyObject]!
    
    init(topTracks: [AnyObject], artist: NSString!) {
        super.init(nibName: "TopTracksViewController", bundle: nil)
        self.topTracks = topTracks
        self.artist = artist
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.registerNib(UINib(nibName: "SongCell", bundle: nil), forCellReuseIdentifier: "SongCell")
        
        self.navigationItem.title = "Top Tracks"
    }
    
    override func viewWillAppear(animated: Bool) {
        self.screenName = "Top Tracks"
        super.viewWillAppear(animated)
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.topTracks.count
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("SongCell",
            forIndexPath: indexPath) as SongCell
        
        let topTrack = self.topTracks[indexPath.row] as LastFmTrack
        cell.songLabel.text = topTrack.name
        cell.infoLabel.text = topTrack.playcount.integerValue.abbreviateNumber() + " plays"
        if let image = topTrack.image {
            cell.songImageView.sd_setImageWithURL(NSURL(string: image))
        } else {
            cell.songImageView.image = UIImage(named: "nowPlayingDefault")
        }
        
        //cell.buyButton.hidden = false
        cell.selectionStyle = .None
        cell.accessoryType = .None
        
        cell.buyButton.addTarget(self, action: "fetchBuyLinks:", forControlEvents: .TouchUpInside)
        cell.buyButton.tag = indexPath.row
        
        return cell
    }
    
    func fetchBuyLinks(sender: AnyObject?) {
        if let button = sender as? UIButton {
            print("Button tag: \(button.tag)\n")
            print("fetching buy links for top tracks...")
            
            let topTrack = self.topTracks[button.tag] as LastFmTrack
            
            var lastFmTrackBuyLinksRequest = LastFmTrackBuyLinksRequest(artist: self.artist, title: topTrack.name)
            lastFmTrackBuyLinksRequest.delegate = self
            lastFmTrackBuyLinksRequest.sendURLRequest()
        }
    }
    
    func lastFmTrackBuyLinksRequestDidComplete(request: LastFmTrackBuyLinksRequest, didCompleteWithBuyLinks buyLinks: [AnyObject]?) {
        self.songBuyLinks = buyLinks
        
        if let buyLinks = songBuyLinks {
            if buyLinks.count > 0 {
                actionSheet = LastFmBuyLinksViewController(buyLinks: buyLinks)
                actionSheet.showInView(self.view)
            } else {
                showBuyAlbumError()
            }
        } else {
            showBuyAlbumError()
        }
    }
    
    private func showBuyAlbumError() {
        UIAlertView(title: "Error!",
            message: "Unable to find buy links for that song.",
            delegate: self,
            cancelButtonTitle: "Ok").show();
    }
}