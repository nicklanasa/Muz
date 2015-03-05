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
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    let artist: NSString!
    
    var tracks: [AnyObject] = [AnyObject]() {
        didSet {
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.activityIndicator.stopAnimating()
                self.tableView.reloadData()
            })
        }
    }
    
    var albums: [AnyObject]! {
        didSet {
            var albumsIds = NSMutableArray()
            for album in albums as [NSDictionary] {
                if let albumID = album.objectForKey("collectionId") as? NSNumber {
                    albumsIds.addObject(albumID.integerValue)
                }
            }
            
            ItunesSearch.sharedInstance().getTracksForAlbums(albumsIds, limitOrNil: NSNumber(int: 30), sucessHandler: { (tracks) -> Void in
                var topTracks = NSMutableArray()
                for track in tracks as [NSDictionary] {
                    if let trackID = track.objectForKey("trackId") as? NSNumber {
                        topTracks.addObject(track)
                    }
                }
                
                self.tracks = topTracks
            }) { (error) -> Void in
                
            }
        }
    }
    
    var actionSheet: LastFmBuyLinksViewController!
    var songBuyLinks: [AnyObject]!
    
    init(topTracks: [AnyObject], artist: NSString!) {
        super.init(nibName: "TopTracksViewController", bundle: nil)
        self.artist = artist
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.registerNib(UINib(nibName: "TopAlbumCell", bundle: nil), forCellReuseIdentifier: "TopAlbumCell")
        
        self.navigationItem.title = self.artist
        
        ItunesSearch.sharedInstance().affiliateToken = "10lSyo";
        ItunesSearch.sharedInstance().getIdForArtist(self.artist, successHandler: { (artists) -> Void in
            if artists.count > 0 {
                if let artistDict = artists.first as? NSDictionary {
                    if let artistID = artistDict.objectForKey("artistId") as? NSNumber {
                        ItunesSearch.sharedInstance().getAlbumsForArtist(artistID, limitOrNil: 100, successHandler: { (albums) -> Void in
                                self.albums = albums
                            }, failureHandler: { (error) -> Void in
                                print(error)
                                self.activityIndicator.stopAnimating()
                        })
                    }
                }
            }
            
            }, failureHandler: { (error) -> Void in
                self.activityIndicator.stopAnimating()
        })
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.tracks.count
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("TopAlbumCell",
            forIndexPath: indexPath) as TopAlbumCell
        
        let topTrack = self.tracks[indexPath.row] as NSDictionary
        cell.songLabel.text = topTrack.objectForKey("trackName") as? String
        cell.infoLabel.text = topTrack.objectForKey("collectionName") as? String
        if let image = topTrack.objectForKey("artworkUrl100") as? String {
            cell.songImageView.sd_setImageWithURL(NSURL(string: image))
        } else {
            cell.songImageView.image = UIImage(named: "nowPlayingDefault")
        }
        
        cell.buyButton.hidden = true
        cell.selectionStyle = .None
        cell.accessoryType = .None
        
        cell.buyButton.tag = indexPath.row
        
        if let trackPrice = topTrack["trackPrice"] as? NSNumber {
            if let trackLink = topTrack["trackViewUrl"] as? String {
                cell.buyButton.setTitle("$\(trackPrice.description)", forState: .Normal)
                cell.buyButton.addTarget(self, action: "openTrackLink:", forControlEvents: .TouchUpInside)
                cell.buyButton.hidden = false
            }
        }
        
        return cell
    }
    
    func openTrackLink(sender: AnyObject?) {
        if let button = sender as? UIButton {
            print("Button tag: \(button.tag)\n")
            
            let track = self.tracks[button.tag] as NSDictionary
            if let trackLink = track["trackViewUrl"] as? String {
                LocalyticsSession.shared().tagEvent("Buy track button tapped")
                UIApplication.sharedApplication().openURL(NSURL(string: trackLink)!)
            }
            
        }
    }
    
    func fetchBuyLinks(sender: AnyObject?) {
        if let button = sender as? UIButton {
//            print("Button tag: \(button.tag)\n")
//            print("fetching buy links for top tracks...")
//            
//            let topTrack = self.topTracks[button.tag] as LastFmTrack
//            
//            var lastFmTrackBuyLinksRequest = LastFmTrackBuyLinksRequest(artist: self.artist, title: topTrack.name)
//            lastFmTrackBuyLinksRequest.delegate = self
//            lastFmTrackBuyLinksRequest.sendURLRequest()
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