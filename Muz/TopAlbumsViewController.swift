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
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var topAlbums: [AnyObject]!
    
    var albums: [AnyObject] = [AnyObject]() {
        didSet {
            DispatchQueue.main.async(execute: { () -> Void in
                self.activityIndicator.stopAnimating()
                self.tableView.reloadData()
            })
        }
    }
    
    var actionSheet: LastFmBuyLinksViewController!
    var albumBuyLinks: [AnyObject]!
    
    init(topAlbums: [AnyObject]) {
        super.init(nibName: "TopAlbumsViewController", bundle: nil)
        
        ItunesSearch.sharedInstance().affiliateToken = "10lSyo"
        
        self.topAlbums = topAlbums
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.register(UINib(nibName: "TopAlbumCell", bundle: nil), forCellReuseIdentifier: "TopAlbumCell")
        
        self.navigationItem.title = "Top Albums"
        
        if let album = self.topAlbums.first as? LastFmAlbum {
            ItunesSearch.sharedInstance().getIdForArtist(album.artist, successHandler: { (artists) -> Void in
                if (artists?.count)! > 0 {
                    if let artistDict = artists?.first as? NSDictionary {
                        if let artistID = artistDict.object(forKey: "artistId") as? NSNumber {
                            ItunesSearch.sharedInstance().getAlbumsForArtist(artistID, limitOrNil: 100,
                                successHandler: { (albums) -> Void in
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
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.screenName = "Top Albums"
        super.viewWillAppear(animated)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.albums.count
    }
    
    func numberOfSectionsInTableView(_ tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAtIndexPath indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "TopAlbumCell",
            for: indexPath) as! TopAlbumCell
        
        let album = self.albums[indexPath.row] as! NSDictionary
        cell.infoLabel.text = album["artistName"] as? String
        if let albumName = album["collectionName"] as? String {
            if let rating = album["contentAdvisoryRating"] as? String {
                cell.songLabel.text = albumName + " - " + rating
            } else {
                cell.songLabel.text = albumName
            }
        }
        
        if let image = album["artworkUrl100"] as? String {
            cell.songImageView.sd_setImage(with: URL(string: image))
        } else {
            cell.songImageView.image = UIImage(named: "nowPlayingDefault")
        }
        
        cell.buyButton.tag = indexPath.row
        cell.buyButton.isHidden = true
        
        if let albumPrice = album["collectionPrice"] as? NSNumber {
            if let _ = album["collectionViewUrl"] as? String {
                cell.buyButton.setTitle("$\(albumPrice.description)", for: UIControlState())
                cell.buyButton.addTarget(self, action: #selector(TopAlbumsViewController.openAlbumLink(_:)), for: .touchUpInside)
                cell.buyButton.isHidden = false
            }
        }
        
        return cell
    }
    
    func openAlbumLink(_ sender: AnyObject?) {
        if let button = sender as? UIButton {
            print("Button tag: \(button.tag)\n", terminator: "")
            
            let album = self.albums[button.tag] as! NSDictionary
            if let albumLink = album["collectionViewUrl"] as? String {
                UIApplication.shared.openURL(URL(string: albumLink)!)
            }
        }
    }
    
    func fetchBuyLinks(_ sender: AnyObject?) {
        if let button = sender as? UIButton {
            print("Button tag: \(button.tag)\n", terminator: "")
            print("fetching buy links for top albums...", terminator: "")
            
            let topAlbum = self.topAlbums[button.tag] as! LastFmAlbum
            
            let lastFmAlbumBuyLinksRequest = LastFmAlbumBuyLinksRequest(artist: topAlbum.artist, album: topAlbum.title)
            lastFmAlbumBuyLinksRequest.delegate = self
            lastFmAlbumBuyLinksRequest.sendURLRequest()
        }
    }
    
    func lastFmAlbumBuyLinksRequestDidComplete(_ request: LastFmAlbumBuyLinksRequest, didCompleteWithBuyLinks buyLinks: [AnyObject]?) {
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
    
    fileprivate func showBuyAlbumError() {
        UIAlertView(title: "Error!",
            message: "Unable to find buy links for that album.",
            delegate: self,
            cancelButtonTitle: "Ok").show();
    }
}
