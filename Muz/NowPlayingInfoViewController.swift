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

enum LastFmCellType: NSInteger {
    case ArtistInfo
    case Events
}

class NowPlayingInfoViewController: RootViewController,
UITableViewDelegate,
UITableViewDataSource,
LyricsRequestDelegate,
LastFmArtistInfoRequestDelegate,
LastFmSimiliarArtistsRequestDelegate,
LastFmArtistEventsRequestDelegate,
UICollectionViewDelegate,
UICollectionViewDataSource,
LastFmAlbumBuyLinksRequestDelegate,
LastFmTrackBuyLinksRequestDelegate,
LastFmTopAlbumsRequestDelegate,
LastFmTopTracksRequestDelegate,
LastFmArtistInfoCellDelegate {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    
    var artistsController: NSFetchedResultsController!
    
    var lyricsRequest: LyricsRequest?
    var azLyricsRequest: NSURLRequest!
    
    var item: MPMediaItem!
    var lyrics: NSString?
    var artist: NSString?
    var lastFmArtist: LastFmArtist?
    var similiarArtists: [AnyObject]?
    var isShowingLastFm = false
    var isForSimiliarArtist = false
    
    var lyricsCell: NowPlayingInfoLyricsCell!
    var artistInfoCell: LastFmArtistInfoCell!
    var lastFmEventCell: LastFmEventCell!
    
    var albumBuyLinks: [AnyObject]?
    var songBuyLinks: [AnyObject]?
    var topAlbums: [AnyObject]?
    var topTracks: [AnyObject]?
    
    var events: [AnyObject]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.registerNib(UINib(nibName: "LastFmArtistInfoCell", bundle: nil), forCellReuseIdentifier: "LastFmArtistCell")
        tableView.registerNib(UINib(nibName: "LastFmEventCell", bundle: nil), forCellReuseIdentifier: "LastFmEventCell")
        
        tableView.autoresizingMask = .FlexibleWidth | .FlexibleHeight
        view.autoresizingMask = .FlexibleWidth | .FlexibleHeight
        
        segmentedControl.addTarget(self, action: "handleSegmentedControlChange", forControlEvents: .ValueChanged)
        
        let lyricsCellNib = UINib(nibName: "NowPlayingInfoLyricsCell", bundle: nil)
        lyricsCell = lyricsCellNib.instantiateWithOwner(self, options: nil)[0] as NowPlayingInfoLyricsCell
        
        let lastFmEventCellNib = UINib(nibName: "LastFmEventCell", bundle: nil)
        lastFmEventCell = lastFmEventCellNib.instantiateWithOwner(self, options: nil)[0] as? LastFmEventCell
        
        let artistInfoCellNib = UINib(nibName: "LastFmArtistInfoCell", bundle: nil)
        artistInfoCell = artistInfoCellNib.instantiateWithOwner(self, options: nil)[0] as? LastFmArtistInfoCell
        
        artistInfoCell.delegate = self
        
        if isForSimiliarArtist {
            configureForSimiliarArtist()
        } else {
            self.navigationController?.view.addSubview(segmentedControl)
            segmentedControl.alpha = 1.0
            
            configureForItem()
        }
        
        self.checkLibraryForArtist()
    }
    
    func checkLibraryForArtist() {
        if self.artist == nil {
            if let item = self.item {
                self.artist = self.item.artist
            }
        }
        
        if let artist = self.artist {
            let predicate = NSPredicate(format: "name = %@", artist)
            artistsController = DataManager.manager.datastore.artistsController(predicate, sortKey: "name", ascending: true, sectionNameKeyPath: nil)
            if artistsController.performFetch(nil) {
                if artistsController.fetchedObjects?.count > 0 {
                    self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "albums"),
                        style: .Plain,
                        target: self,
                        action: "artistAlbums")
                }
            }
        }
    }
    
    func artistAlbums() {
        let artist = artistsController.fetchedObjects?[0] as Artist
        let artistAlbumsViewController = ArtistAlbumsViewController(artist: artist)
        navigationController?.pushViewController(artistAlbumsViewController, animated: true)
    }
    
    override func viewWillAppear(animated: Bool) {
        if isForSimiliarArtist {
            segmentedControl?.alpha = 0.0
        } else {
            segmentedControl?.alpha = 1.0
        }
        
        self.screenName = "Artist Info"
        
        self.navigationItem.title = ""
        
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(animated: Bool) {
        segmentedControl?.alpha = 0.0
    }
    
    override func viewDidLayoutSubviews() {
        segmentedControl?.center = CGPointMake(UIScreen.mainScreen().bounds.size.width / 2, 40)
    }
    
    override init() {
        super.init(nibName: "NowPlayingInfoViewController", bundle: nil)
    }
    
    init(item: MPMediaItem) {
        super.init(nibName: "NowPlayingInfoViewController", bundle: nil)
        self.item = item
    }
    
    init(artist: NSString, isForSimiliarArtist: Bool) {
        super.init(nibName: "NowPlayingInfoViewController", bundle: nil)
        self.artist = artist
        self.isForSimiliarArtist = isForSimiliarArtist
    }
    
    /**
    Configure the ViewController for Similiar Artists
    */
    private func configureForSimiliarArtist() {
        self.segmentedControl.alpha = 0.0
        
        handleSegmentedControlChange()
        
        requestLastFmDataWithArtist(self.artist)
    }
    
    /**
    Handle the change of the segmentation control.
    */
    func handleSegmentedControlChange() {
        // Tag switch to track in analytics
        switch segmentedControl.selectedSegmentIndex {
        case 0:
            isShowingLastFm = true
        default:
            isShowingLastFm = false
        }
        
        tableView?.reloadData()
    }
    
    /**
    Configure the ViewController with passed in item.
    */
    private func configureForItem() {
        
        if SettingsManager.defaultManager.valueForMoreSetting(.Lyrics) {
            let stringURL = NSString(format: "http://search.azlyrics.com/search.php?q=%@ %@",
                self.item.artist,
                self.item.title).stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)
            print(stringURL)
            let lyricsURL = NSURL(string: stringURL!)!
            /*
            var request = LyricsRequest(url: lyricsURL, item: item)
            request.delegate = self
            request.sendURLRequest()
            */
            azLyricsRequest = NSURLRequest(URL: lyricsURL)
            lyricsCell.updateWithRequest(azLyricsRequest)
        } else {
            lyricsCell.activityIndicator.stopAnimating()
            segmentedControl.selectedSegmentIndex = 0
            segmentedControl.setEnabled(false, forSegmentAtIndex: 1)
        }
        
        if SettingsManager.defaultManager.valueForMoreSetting(.ArtistInfo) {
            requestLastFmDataWithArtist(self.item.artist)
        } else {
            segmentedControl.selectedSegmentIndex = 1
            segmentedControl.setEnabled(false, forSegmentAtIndex: 0)
        }
        
        handleSegmentedControlChange()
    }
    
    func requestLastFmDataWithArtist(artistName: NSString?) {
        var artistLastFmRequest = LastFmArtistInfoRequest(artist: artistName!)
        artistLastFmRequest.delegate = self
        artistLastFmRequest.sendURLRequest()
        
        var similiarArtistLastFmRequest = LastFmSimiliarArtistsRequest(artist: artistName!)
        similiarArtistLastFmRequest.delegate = self
        similiarArtistLastFmRequest.sendURLRequest()
        
        var artistEventsLastFmRequest = LastFmArtistEventsRequest(artist: artistName!)
        artistEventsLastFmRequest.delegate = self
        artistEventsLastFmRequest.sendURLRequest()
        
        var topAlbumsLastFmRequest = LastFmTopAlbumsRequest(artist: artistName!)
        topAlbumsLastFmRequest.delegate = self
        topAlbumsLastFmRequest.sendURLRequest()
        
        var topTracksLastFmRequest = LastFmTopTracksRequest(artist: artistName!)
        topTracksLastFmRequest.delegate = self
        topTracksLastFmRequest.sendURLRequest()

        
        if !isForSimiliarArtist && self.item != nil {
//            var lastFmAlbumBuyLinksRequest = LastFmAlbumBuyLinksRequest(artist: self.item!.artist, album: self.item!.albumTitle)
//            lastFmAlbumBuyLinksRequest.delegate = self
//            lastFmAlbumBuyLinksRequest.sendURLRequest()
//            
//            var lastFmTrackBuyLinksRequest = LastFmTrackBuyLinksRequest(artist: self.item!.artist, title: self.item!.title)
//            lastFmTrackBuyLinksRequest.delegate = self
//            lastFmTrackBuyLinksRequest.sendURLRequest()
        }
    }
    
    func lastFmArtistInfoRequestDidComplete(request: LastFmArtistInfoRequest, didCompleteWithLastFmArtist artist: LastFmArtist?) {
        self.lastFmArtist = artist
        reloadTable()
    }
    
    func lastFmSimiliarArtistsRequestDidComplete(request: LastFmSimiliarArtistsRequest, didCompleteWithLastFmArtists artists: [AnyObject]?) {
        self.similiarArtists = artists
        artistInfoCell.similiarActivityIndicator.stopAnimating()
        artistInfoCell.bioActivityIndicator.stopAnimating()
        reloadTable()
    }
    
    func lastFmArtistEventsRequestDidComplete(request: LastFmArtistEventsRequest, didCompleteWithEvents events: [AnyObject]?)
    {
        self.events = events
        reloadTable()
    }
    
    func lastFmAlbumBuyLinksRequestDidComplete(request: LastFmAlbumBuyLinksRequest, didCompleteWithBuyLinks buyLinks: [AnyObject]?) {
        self.albumBuyLinks = buyLinks
        reloadTable()
    }
    
    func lastFmTrackBuyLinksRequestDidComplete(request: LastFmTrackBuyLinksRequest, didCompleteWithBuyLinks buyLinks: [AnyObject]?) {
        self.songBuyLinks = buyLinks
        reloadTable()
    }

    func lyricsRequestDidComplete(request: LyricsRequest, didCompleteWithLyrics lyrics: String?) {
        self.lyrics = lyrics
        reloadTable()
    }
    
    func lastFmTopAlbumsRequestDidComplete(request: LastFmTopAlbumsRequest, didCompleteWithAlbums albums: [AnyObject]?) {
        self.topAlbums = albums
        reloadTable()
    }
    
    func lastFmTopTracksRequestDidComplete(request: LastFmTopTracksRequest, didCompleteWithTracks tracks: [AnyObject]?) {
        self.topTracks = tracks
        reloadTable()
    }
    
    private func reloadTable() {
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.lyricsCell.activityIndicator.stopAnimating()
            self.tableView.reloadData()
        })
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isShowingLastFm {
            if self.events?.count > 0 {
                return 2
            } else {
                return 1
            }
        } else {
            return 1
        }
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if isShowingLastFm {
            if indexPath.row == 0 {
                return LastFmArtistInfoCellHeight
            } else {
                return lastFmEventCell.cellHeight
            }
        }
        return tableView.frame.height
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if isShowingLastFm {
            switch indexPath.row {
            case LastFmCellType.ArtistInfo.rawValue:
                artistInfoCell.updateWithArtist(lastFmArtist)
                
                artistInfoCell.collectionView.delegate = self
                artistInfoCell.collectionView.dataSource = self
                
                let nib = UINib(nibName: "SimiliarArtistCollectionViewCell", bundle: nil)
                artistInfoCell.collectionView.registerNib(nib, forCellWithReuseIdentifier: "SimiliarArtistCell")
                
                artistInfoCell.topTracks = topTracks
                artistInfoCell.topAlbums = topAlbums
                
                artistInfoCell.buySongButton.alpha = 1.0
                artistInfoCell.buyAlbumButton.alpha = 1.0
                
                return artistInfoCell
            default:
                let nib = UINib(nibName: "LastFmEventInfoCell", bundle: nil)
                lastFmEventCell.collectionView.registerNib(nib, forCellWithReuseIdentifier: "LastFmEventInfoCell")
                
                lastFmEventCell.collectionView.delegate = self
                lastFmEventCell.collectionView.dataSource = self
                
                lastFmEventCell.updateWithEvents(self.events)
                
                return lastFmEventCell
            }
        } else {
            /*
            if !lyricsCell.activityIndicator.isAnimating() {
                if let lyrics = self.lyrics {
                    lyricsCell.updateWithLyrics(lyrics)
                } else {
                    lyricsCell.updateWithLyrics(self.item.lyrics)
                }
            }
            */
            return lyricsCell
        }
    }
    
    // MARK: UICollectionViewDataSource
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        if collectionView == lastFmEventCell?.collectionView {
            return self.events?.count ?? 0
        } else {
            return self.similiarArtists?.count ?? 0
        }
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        if collectionView == lastFmEventCell?.collectionView {
            var cell = collectionView.dequeueReusableCellWithReuseIdentifier("LastFmEventInfoCell",
                forIndexPath: indexPath) as LastFmEventInfoCell
            
            if let event = events?[indexPath.row] as? LastFmEvent {
                cell.updateWithEvent(event)
            }
            
            return cell
        } else {
            var cell = collectionView.dequeueReusableCellWithReuseIdentifier("SimiliarArtistCell",
                forIndexPath: indexPath) as SimiliarArtistCollectionViewCell
            
            if let artist = similiarArtists?[indexPath.row] as? LastFmArtist {
                cell.updateWithArtist(artist)
            }
            
            return cell
        }
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        if collectionView == lastFmEventCell?.collectionView {
            if let event = self.events?[indexPath.row] as? LastFmEvent {
                self.navigationController?.pushViewController(LastFmEventInfoController(event: event), animated: true)
            }
        } else {
            if let lastFmArtist = self.similiarArtists?[indexPath.row] as? LastFmArtist {
                let nowPlaying = NowPlayingInfoViewController(artist: lastFmArtist.name, isForSimiliarArtist: true)
                self.navigationController?.pushViewController(nowPlaying, animated: true)
            }
        }
    }
    
    func lastFmArtistInfoCell(cell: LastFmArtistInfoCell, didTapTopAlbumsButton albums: [AnyObject]?) {
        if let topAlbums = albums {
            let topAlbumsViewController = TopAlbumsViewController(topAlbums: topAlbums)
            self.navigationController?.pushViewController(topAlbumsViewController, animated: true)
        }
    }
    
    func lastFmArtistInfoCell(cell: LastFmArtistInfoCell, didTapTopTracksButton tracks: [AnyObject]?) {
        if let topTracks = tracks {
            if let artist = similiarArtists?[self.tableView.indexPathForCell(cell)!.row] as? LastFmArtist {
                let topTracksViewController = TopTracksViewController(topTracks: topTracks, artist: self.artist)
                self.navigationController?.pushViewController(topTracksViewController, animated: true)
            }
        }
    }
}