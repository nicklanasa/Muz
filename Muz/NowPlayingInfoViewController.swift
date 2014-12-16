//
//  NowPlayingInfoViewController.swift
//  Muz
//
//  Created by Nick Lanasa on 12/12/14.
//  Copyright (c) 2014 Nytek Productions. All rights reserved.
//

import Foundation
import UIKit
import CoreData
import MediaPlayer

class NowPlayingInfoViewController: RootViewController,
UITableViewDelegate,
UITableViewDataSource,
LyricsRequestDelegate,
LastFmArtistInfoRequestDelegate,
LastFmSimiliarArtistsRequestDelegate,
UICollectionViewDelegate,
UICollectionViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    
    var lyricsRequest: LyricsRequest?
    
    var item: MPMediaItem?
    var lyrics = ""
    var lastFmArtist: LastFmArtist?
    var similiarArtists: [AnyObject]?
    var isShowingLastFm = false
    var isForSimiliarArtist = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.registerNib(UINib(nibName: "NowPlayingInfoLyricsCell", bundle: nil), forCellReuseIdentifier: "Cell")
        tableView.registerNib(UINib(nibName: "LastFmArtistInfoCell", bundle: nil), forCellReuseIdentifier: "LastFmArtistCell")
        
        tableView.autoresizingMask = .FlexibleWidth | .FlexibleHeight
        view.autoresizingMask = .FlexibleWidth | .FlexibleHeight
        
        segmentedControl.addTarget(self, action: "handleSegmentedControlChange", forControlEvents: .ValueChanged)
        
        if isForSimiliarArtist {
            configureForSimiliarArtist()
        }
    }
    
    override init() {
        super.init(nibName: "NowPlayingInfoViewController", bundle: nil)
    }
    
    init(artist: LastFmArtist, isForSimiliarArtist: Bool) {
        super.init(nibName: "NowPlayingInfoViewController", bundle: nil)
        self.lastFmArtist = artist
        self.isForSimiliarArtist = isForSimiliarArtist
    }
    
    private func configureForSimiliarArtist() {
        self.segmentedControl.alpha = 0.0
        self.segmentedControl.selectedSegmentIndex = 1
        
        var frame = self.tableView.frame
        frame.origin.y -= self.segmentedControl.frame.size.height
        frame.size.height += self.segmentedControl.frame.size.height
        self.tableView.frame = frame
        
        handleSegmentedControlChange()
        
        requestLastFmDataWithArtist(self.lastFmArtist?.name)
    }
    
    func handleSegmentedControlChange() {
        switch segmentedControl.selectedSegmentIndex {
        case 0:
            isShowingLastFm = false
        default:
            isShowingLastFm = true
        }
        
        tableView.beginUpdates()
        tableView.reloadRowsAtIndexPaths([NSIndexPath(forRow: 0, inSection: 0)], withRowAnimation: .Fade)
        tableView.endUpdates()
    }
    
    func updateWithItem(item: MPMediaItem) {
        self.item = item
        
        let stringURL = NSString(format: "http://search.azlyrics.com/search.php?q=%@ %@", item.artist, item.title).stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)
        let lyricsURL = NSURL(string: stringURL!)!
        var request = LyricsRequest(url: lyricsURL, item: item)
        request.delegate = self
        request.sendURLRequest()
        
        requestLastFmDataWithArtist(item.artist)
    }
    
    func requestLastFmDataWithArtist(artistName: NSString?) {
        var artistLastFmRequest = LastFmArtistInfoRequest(artist: artistName!)
        artistLastFmRequest.delegate = self
        artistLastFmRequest.sendURLRequest()
        
        var similiarArtistLastFmRequest = LastFmSimiliarArtistsRequest(artist: artistName!)
        similiarArtistLastFmRequest.delegate = self
        similiarArtistLastFmRequest.sendURLRequest()
    }
    
    func lastFmArtistInfoRequestDidComplete(request: LastFmArtistInfoRequest, didCompleteWithLastFmArtist artist: LastFmArtist?) {
        self.lastFmArtist = artist
        tableView.reloadData()
    }
    
    func LastFmSimiliarArtistsRequestDidComplete(request: LastFmSimiliarArtistsRequest, didCompleteWithLastFmArtists artists: [AnyObject]?) {
        self.similiarArtists = artists
        tableView.reloadData()
    }
    
    func lyricsRequestDidComplete(request: LyricsRequest, didCompleteWithLyrics lyrics: String) {
        self.lyrics = lyrics
        tableView.reloadData()
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if isShowingLastFm {
            return LastFmArtistInfoCellHeight
        }
        return tableView.frame.height
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if isShowingLastFm {
            var artistInfoCell = tableView.dequeueReusableCellWithIdentifier("LastFmArtistCell") as LastFmArtistInfoCell
            artistInfoCell.updateWithArtist(lastFmArtist)
            
            artistInfoCell.collectionView.delegate = self
            artistInfoCell.collectionView.dataSource = self
            
            let nib = UINib(nibName: "SimiliarArtistCollectionViewCell", bundle: nil)
            artistInfoCell.collectionView.registerNib(nib, forCellWithReuseIdentifier: "SimiliarArtistCell")
            
            return artistInfoCell
        } else {
            var cell = tableView.dequeueReusableCellWithIdentifier("Cell") as NowPlayingInfoLyricsCell
            cell.updateWithLyrics(self.lyrics)
            return cell
        }
    }
    
    // MARK: UICollectionViewDataSource
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.similiarArtists?.count ?? 0
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        var cell = collectionView.dequeueReusableCellWithReuseIdentifier("SimiliarArtistCell",
            forIndexPath: indexPath) as SimiliarArtistCollectionViewCell
        
        if let artist = similiarArtists?[indexPath.row] as? LastFmArtist {
            cell.updateWithArtist(artist)
        }
        
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        if let artist = similiarArtists?[indexPath.row] as? LastFmArtist {
            self.navigationController?.pushViewController(NowPlayingInfoViewController(artist: artist, isForSimiliarArtist: true), animated: true)
        }
    }
}