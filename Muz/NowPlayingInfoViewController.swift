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
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


enum LastFmCellType: NSInteger {
    case artistInfo
    case events
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
    
    var artistsController: NSFetchedResultsController<NSFetchRequestResult>!
    
    var lyricsRequest: LyricsRequest?
    var azLyricsRequest: URLRequest!
    
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
        
        tableView.register(UINib(nibName: "LastFmArtistInfoCell", bundle: nil), forCellReuseIdentifier: "LastFmArtistCell")
        tableView.register(UINib(nibName: "LastFmEventCell", bundle: nil), forCellReuseIdentifier: "LastFmEventCell")
        
        tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        segmentedControl.addTarget(self, action: #selector(NowPlayingInfoViewController.handleSegmentedControlChange), for: .valueChanged)
        
        let lyricsCellNib = UINib(nibName: "NowPlayingInfoLyricsCell", bundle: nil)
        lyricsCell = lyricsCellNib.instantiate(withOwner: self, options: nil)[0] as! NowPlayingInfoLyricsCell
        
        let lastFmEventCellNib = UINib(nibName: "LastFmEventCell", bundle: nil)
        lastFmEventCell = lastFmEventCellNib.instantiate(withOwner: self, options: nil)[0] as? LastFmEventCell
        
        let artistInfoCellNib = UINib(nibName: "LastFmArtistInfoCell", bundle: nil)
        artistInfoCell = artistInfoCellNib.instantiate(withOwner: self, options: nil)[0] as? LastFmArtistInfoCell
        
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
            if let _ = self.item {
                self.artist = self.item.artist as! NSString
            }
        }
        
        if let artist = self.artist {
            let predicate = NSPredicate(format: "name = %@", artist)
            artistsController = DataManager.manager.datastore.artistsController(predicate, sortKey: "name", ascending: true, sectionNameKeyPath: nil)
            do {
                try artistsController.performFetch()
                if artistsController.fetchedObjects?.count > 0 {
                    self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "albums"),
                        style: .plain,
                        target: self,
                        action: #selector(NowPlayingInfoViewController.artistAlbums))
                }
            } catch _ {
            }
        }
    }
    
    func artistAlbums() {
        let artist = artistsController.fetchedObjects?[0] as! Artist
        let artistAlbumsViewController = ArtistAlbumsViewController(artist: artist)
        navigationController?.pushViewController(artistAlbumsViewController, animated: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if isForSimiliarArtist {
            segmentedControl?.alpha = 0.0
        } else {
            segmentedControl?.alpha = 1.0
        }
        
        self.screenName = "Artist Info"
        
        self.navigationItem.title = ""
        
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        segmentedControl?.alpha = 0.0
    }
    
    override func viewDidLayoutSubviews() {
        segmentedControl?.center = CGPoint(x: UIScreen.main.bounds.size.width / 2, y: 40)
    }
    
    init() {
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
    fileprivate func configureForSimiliarArtist() {
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
    fileprivate func configureForItem() {
        
        if SettingsManager.defaultManager.valueForMoreSetting(.lyrics) {
            if let title = self.item.title, let artist = self.item.artist {
                let stringURL = NSString(format: "http://search.azlyrics.com/search.php?q=%@ %@",
                    artist,
                    title).addingPercentEscapes(using: String.Encoding.utf8.rawValue)
                print(stringURL, terminator: "")
                let lyricsURL = URL(string: stringURL!)!
                /*
                var request = LyricsRequest(url: lyricsURL, item: item)
                request.delegate = self
                request.sendURLRequest()
                */
                azLyricsRequest = URLRequest(url: lyricsURL)
                lyricsCell.updateWithRequest(azLyricsRequest)
            }
        } else {
            lyricsCell.activityIndicator.stopAnimating()
            segmentedControl.selectedSegmentIndex = 0
            segmentedControl.setEnabled(false, forSegmentAt: 1)
        }
        
        if SettingsManager.defaultManager.valueForMoreSetting(.artistInfo) {
            requestLastFmDataWithArtist(self.item.artist as! NSString)
        } else {
            segmentedControl.selectedSegmentIndex = 1
            segmentedControl.setEnabled(false, forSegmentAt: 0)
        }
        
        handleSegmentedControlChange()
    }
    
    func requestLastFmDataWithArtist(_ artistName: NSString?) {
        let artistLastFmRequest = LastFmArtistInfoRequest(artist: artistName! as String)
        artistLastFmRequest.delegate = self
        artistLastFmRequest.sendURLRequest()
        
        let similiarArtistLastFmRequest = LastFmSimiliarArtistsRequest(artist: artistName! as String)
        similiarArtistLastFmRequest.delegate = self
        similiarArtistLastFmRequest.sendURLRequest()
        
        let artistEventsLastFmRequest = LastFmArtistEventsRequest(artist: artistName! as String)
        artistEventsLastFmRequest.delegate = self
        artistEventsLastFmRequest.sendURLRequest()
        
        let topAlbumsLastFmRequest = LastFmTopAlbumsRequest(artist: artistName! as String)
        topAlbumsLastFmRequest.delegate = self
        topAlbumsLastFmRequest.sendURLRequest()
        
        let topTracksLastFmRequest = LastFmTopTracksRequest(artist: artistName! as String)
        topTracksLastFmRequest.delegate = self
        topTracksLastFmRequest.sendURLRequest()
    }
    
    func lastFmArtistInfoRequestDidComplete(_ request: LastFmArtistInfoRequest, didCompleteWithLastFmArtist artist: LastFmArtist?) {
        self.lastFmArtist = artist
        reloadTable()
    }
    
    func lastFmSimiliarArtistsRequestDidComplete(_ request: LastFmSimiliarArtistsRequest, didCompleteWithLastFmArtists artists: [AnyObject]?) {
        self.similiarArtists = artists
        artistInfoCell.similiarActivityIndicator.stopAnimating()
        artistInfoCell.bioActivityIndicator.stopAnimating()
        reloadTable()
    }
    
    func lastFmArtistEventsRequestDidComplete(_ request: LastFmArtistEventsRequest, didCompleteWithEvents events: [AnyObject]?)
    {
        self.events = events
        reloadTable()
    }
    
    func lastFmAlbumBuyLinksRequestDidComplete(_ request: LastFmAlbumBuyLinksRequest, didCompleteWithBuyLinks buyLinks: [AnyObject]?) {
        self.albumBuyLinks = buyLinks
        reloadTable()
    }
    
    func lastFmTrackBuyLinksRequestDidComplete(_ request: LastFmTrackBuyLinksRequest, didCompleteWithBuyLinks buyLinks: [AnyObject]?) {
        self.songBuyLinks = buyLinks
        reloadTable()
    }

    func lyricsRequestDidComplete(_ request: LyricsRequest, didCompleteWithLyrics lyrics: String?) {
        self.lyrics = lyrics as! NSString
        reloadTable()
    }
    
    func lastFmTopAlbumsRequestDidComplete(_ request: LastFmTopAlbumsRequest, didCompleteWithAlbums albums: [AnyObject]?) {
        self.topAlbums = albums
        reloadTable()
    }
    
    func lastFmTopTracksRequestDidComplete(_ request: LastFmTopTracksRequest, didCompleteWithTracks tracks: [AnyObject]?) {
        self.topTracks = tracks
        reloadTable()
    }
    
    fileprivate func reloadTable() {
        DispatchQueue.main.async(execute: { () -> Void in
            self.lyricsCell.activityIndicator.stopAnimating()
            self.tableView.reloadData()
        })
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
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
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if isShowingLastFm {
            if indexPath.row == 0 {
                return LastFmArtistInfoCellHeight
            } else {
                return lastFmEventCell.cellHeight
            }
        }
        return tableView.frame.height
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if isShowingLastFm {
            switch indexPath.row {
            case LastFmCellType.artistInfo.rawValue:
                artistInfoCell.updateWithArtist(lastFmArtist)
                
                artistInfoCell.collectionView.delegate = self
                artistInfoCell.collectionView.dataSource = self
                
                let nib = UINib(nibName: "SimiliarArtistCollectionViewCell", bundle: nil)
                artistInfoCell.collectionView.register(nib, forCellWithReuseIdentifier: "SimiliarArtistCell")
                
                artistInfoCell.topTracks = topTracks
                artistInfoCell.topAlbums = topAlbums
                
                artistInfoCell.buySongButton.alpha = 1.0
                artistInfoCell.buyAlbumButton.alpha = 1.0
                
                return artistInfoCell
            default:
                let nib = UINib(nibName: "LastFmEventInfoCell", bundle: nil)
                lastFmEventCell.collectionView.register(nib, forCellWithReuseIdentifier: "LastFmEventInfoCell")
                
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
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        if collectionView == lastFmEventCell?.collectionView {
            return self.events?.count ?? 0
        } else {
            return self.similiarArtists?.count ?? 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if collectionView == lastFmEventCell?.collectionView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "LastFmEventInfoCell",
                for: indexPath) as! LastFmEventInfoCell
            
            if let event = events?[indexPath.row] as? LastFmEvent {
                cell.updateWithEvent(event)
            }
            
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SimiliarArtistCell",
                for: indexPath) as! SimiliarArtistCollectionViewCell
            
            if let artist = similiarArtists?[indexPath.row] as? LastFmArtist {
                cell.updateWithArtist(artist)
            }
            
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        if collectionView == lastFmEventCell?.collectionView {
            if let event = self.events?[indexPath.row] as? LastFmEvent {
                self.navigationController?.pushViewController(LastFmEventInfoController(event: event), animated: true)
            }
        } else {
            if let lastFmArtist = self.similiarArtists?[indexPath.row] as? LastFmArtist {
                let nowPlaying = NowPlayingInfoViewController(artist: lastFmArtist.name as! NSString, isForSimiliarArtist: true)
                self.navigationController?.pushViewController(nowPlaying, animated: true)
            }
        }
    }
    
    func lastFmArtistInfoCell(_ cell: LastFmArtistInfoCell, didTapTopAlbumsButton albums: [AnyObject]?) {
        if let topAlbums = albums {
            let topAlbumsViewController = TopAlbumsViewController(topAlbums: topAlbums)
            self.navigationController?.pushViewController(topAlbumsViewController, animated: true)
        }
    }
    
    func lastFmArtistInfoCell(_ cell: LastFmArtistInfoCell, didTapTopTracksButton tracks: [AnyObject]?) {
        if let topTracks = tracks {
            if let artist = similiarArtists?[self.tableView.indexPath(for: cell)!.row] as? LastFmArtist {
                let topTracksViewController = TopTracksViewController(topTracks: topTracks, artist: artist.name)
                self.navigationController?.pushViewController(topTracksViewController, animated: true)
            }
        }
    }
}
