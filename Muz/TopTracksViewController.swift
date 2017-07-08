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
    
    let artist: String!
    
    var tracks: [AnyObject] = [AnyObject]() {
        didSet {
            DispatchQueue.main.async(execute: { () -> Void in
                self.activityIndicator.stopAnimating()
                self.tableView.reloadData()
            })
        }
    }
    
    var albums: [AnyObject]! {
        didSet {
            let albumsIds = NSMutableArray()
            for album in albums as! [NSDictionary] {
                if let albumID = album.object(forKey: "collectionId") as? NSNumber {
                    albumsIds.add(albumID.intValue)
                }
            }
            
            ItunesSearch.sharedInstance().getTracksForAlbums(albumsIds as [AnyObject], limitOrNil: NSNumber(value: 30 as Int32), sucessHandler: { (tracks) -> Void in
                let topTracks = NSMutableArray()
                for track in tracks as! [NSDictionary] {
                    if let _ = track.object(forKey: "trackId") as? NSNumber {
                        topTracks.add(track)
                    }
                }
                
                self.tracks = topTracks as [AnyObject]
            }) { (error) -> Void in
                
            }
        }
    }
    
    var actionSheet: LastFmBuyLinksViewController!
    var songBuyLinks: [AnyObject]!
    
    init(topTracks: [AnyObject], artist: String!) {
        self.artist = artist
        super.init(nibName: "TopTracksViewController", bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.register(UINib(nibName: "TopAlbumCell", bundle: nil), forCellReuseIdentifier: "TopAlbumCell")
        
        self.navigationItem.title = self.artist
        
        ItunesSearch.sharedInstance().affiliateToken = "10lSyo"
        
        ItunesSearch.sharedInstance().getIdForArtist(self.artist, successHandler: { (artists) -> Void in
            if (artists?.count)! > 0 {
                if let artistDict = artists?.first as? NSDictionary {
                    if let artistID = artistDict.object(forKey: "artistId") as? NSNumber {
                        ItunesSearch.sharedInstance().getAlbumsForArtist(artistID, limitOrNil: 100, successHandler: { (albums) -> Void in
                                self.albums = albums
                            }, failureHandler: { (error) -> Void in
                                print(error, terminator: "")
                                self.activityIndicator.stopAnimating()
                        })
                    }
                }
            }
            
            }, failureHandler: { (error) -> Void in
                self.activityIndicator.stopAnimating()
        })
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.tracks.count
    }
    
    func numberOfSectionsInTableView(_ tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAtIndexPath indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "TopAlbumCell",
            for: indexPath) as! TopAlbumCell
        
        let topTrack = self.tracks[indexPath.row] as! NSDictionary
        cell.songLabel.text = topTrack.object(forKey: "trackName") as? String
        cell.infoLabel.text = topTrack.object(forKey: "collectionName") as? String
        if let image = topTrack.object(forKey: "artworkUrl100") as? String {
            cell.songImageView.sd_setImage(with: URL(string: image))
        } else {
            cell.songImageView.image = UIImage(named: "nowPlayingDefault")
        }
        
        cell.buyButton.isHidden = true
        cell.selectionStyle = .none
        cell.accessoryType = .none
        
        cell.buyButton.tag = indexPath.row
        
        if let trackPrice = topTrack["trackPrice"] as? NSNumber {
            if let _ = topTrack["trackViewUrl"] as? String {
                cell.buyButton.setTitle("$\(trackPrice.description)", for: UIControlState())
                cell.buyButton.addTarget(self, action: #selector(TopTracksViewController.openTrackLink(_:)), for: .touchUpInside)
                cell.buyButton.isHidden = false
            }
        }
        
        return cell
    }
    
    func openTrackLink(_ sender: AnyObject?) {
        if let button = sender as? UIButton {
            print("Button tag: \(button.tag)\n", terminator: "")
            
            let track = self.tracks[button.tag] as! NSDictionary
            if let trackLink = track["trackViewUrl"] as? String {
                UIApplication.shared.openURL(URL(string: trackLink)!)
            }
            
        }
    }
    
    func fetchBuyLinks(_ sender: AnyObject?) {
        if let _ = sender as? UIButton {
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
    
    func lastFmTrackBuyLinksRequestDidComplete(_ request: LastFmTrackBuyLinksRequest, didCompleteWithBuyLinks buyLinks: [AnyObject]?) {
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
    
    fileprivate func showBuyAlbumError() {
        UIAlertView(title: "Error!",
            message: "Unable to find buy links for that song.",
            delegate: self,
            cancelButtonTitle: "Ok").show();
    }
}
