//
//  HomeViewController.swift
//  Muz
//
//  Created by Nick Lanasa on 2/7/15.
//  Copyright (c) 2015 Nytek Productions. All rights reserved.
//

import Foundation
import UIKit
import CoreData
import MediaPlayer

enum HomeSectionType: NSInteger {
    case NowPlaying
    case RelatedArtists
    case RecentArtists
    case RecentPlaylists
    case RecentSongs
}

class HomeViewController: RootViewController,
UITableViewDataSource, UITableViewDelegate,
NSFetchedResultsControllerDelegate,
LastFmSimiliarArtistsRequestDelegate,
UICollectionViewDelegate,
UICollectionViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    
    private var similiarArtists: [AnyObject]?
    private var recentArtistSongs: NSArray? {
        didSet {
            self.tableView.reloadData()
        }
    }
    private var recentSongs: NSArray? {
        didSet {
            self.tableView.reloadData()
        }
    }
    
    var similarArtistCell: LastFmSimilarArtistTableCell!
    var recentArtistCell: LastFmSimilarArtistTableCell!
    var nowPlayingCell: NowPlayingTableViewCell!

    private var recentPlaylistsController: NSFetchedResultsController?
    
    override init() {
        super.init(nibName: "HomeViewController", bundle: nil)
        
        self.tabBarItem = UITabBarItem(title: nil,
            image: UIImage(named: "headphones"),
            selectedImage: UIImage(named: "headphones"))
        
        self.tabBarItem.imageInsets = UIEdgeInsetsMake(6, 0, -6, 0)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewWillAppear(animated: Bool) {
        self.screenName = "Now Playing"
        super.viewWillAppear(animated)
        
        self.recentArtistSongs = DataManager.manager.datastore.distinctArtistSongsWithSortKey("lastPlayedDate", limit: 25, ascending: false)
        self.recentSongs = DataManager.manager.datastore.recentlyPlayedSongs(limit: 5)
        
        self.recentPlaylistsController = DataManager.manager.datastore.playlistsControllerWithSortKey(sortKey: "modifiedDate",
            ascending: false,
            limit: 3,
            sectionNameKeyPath: nil)
        self.recentPlaylistsController!.delegate = self
        
        let nowPlayingCellNib = UINib(nibName: "NowPlayingTableViewCell", bundle: nil)
        nowPlayingCell = nowPlayingCellNib.instantiateWithOwner(self, options: nil)[0] as? NowPlayingTableViewCell
        
        self.fetchHomeData()
    }
    
    func fetchHomeData() {
        var recentPlaylistsError: NSError?
        var recentSongsError: NSError?
        if self.recentPlaylistsController!.performFetch(&recentPlaylistsError) {
            if self.recentArtistSongs?.count > 0 {
                if let song = self.recentArtistSongs?[0] as? NSDictionary {
                    var similiarArtistLastFmRequest = LastFmSimiliarArtistsRequest(artist: song.objectForKey("artist") as NSString)
                    similiarArtistLastFmRequest.delegate = self
                    similiarArtistLastFmRequest.sendURLRequest()
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.registerNib(UINib(nibName: "SongCell", bundle: nil), forCellReuseIdentifier: "SongCell")
        self.tableView.registerNib(UINib(nibName: "PlaylistCell", bundle: nil), forCellReuseIdentifier: "PlaylistCell")
        self.tableView.registerNib(UINib(nibName: "ArtistsHeader", bundle: nil), forHeaderFooterViewReuseIdentifier: "Header")
        
        let similarArtistCellNib = UINib(nibName: "LastFmSimilarArtistTableCell", bundle: nil)
        similarArtistCell = similarArtistCellNib.instantiateWithOwner(self, options: nil)[0] as? LastFmSimilarArtistTableCell
        
        let recentArtistCellNib = UINib(nibName: "LastFmSimilarArtistTableCell", bundle: nil)
        recentArtistCell = recentArtistCellNib.instantiateWithOwner(self, options: nil)[0] as? LastFmSimilarArtistTableCell
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "search"),
            style: .Plain,
            target: self,
            action: "showSearch")
    }
    
    func showSearch() {
        self.presentSearchOverlayController(SearchOverlayController(), blurredController: self)
    }

    func lastFmSimiliarArtistsRequestDidComplete(request: LastFmSimiliarArtistsRequest, didCompleteWithLastFmArtists artists: [AnyObject]?) {
        self.similiarArtists = artists
        similarArtistCell.similiarActivityIndicator.stopAnimating()
        self.tableView.reloadData()
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 5
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.recentArtistSongs?.count > 0 && self.recentPlaylistsController != nil {
            if let sectionType = HomeSectionType(rawValue: section) {
                var controller: NSFetchedResultsController!
                switch sectionType {
                case .RecentSongs:
                    return self.recentSongs?.count ?? 0
                case .RecentPlaylists:
                    controller = self.recentPlaylistsController
                    
                    if let numberOfRowsInSection = controller.sections?[0].numberOfObjects {
                        return numberOfRowsInSection
                    } else {
                        return 0
                    }
                default:
                    return 1
                }
            }
        }
        
        return 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let sectionType = HomeSectionType(rawValue: indexPath.section)!
        
        var songCell = tableView.dequeueReusableCellWithIdentifier("SongCell") as SongCell
        
        switch sectionType {
        case .NowPlaying:
            return nowPlayingCell
            
        case .RelatedArtists:
            similarArtistCell.collectionView.delegate = self
            similarArtistCell.collectionView.dataSource = self
            
            let nib = UINib(nibName: "SimiliarArtistCollectionViewCell", bundle: nil)
            similarArtistCell.collectionView.registerNib(nib, forCellWithReuseIdentifier: "SimiliarArtistCell")
            
            similarArtistCell.collectionView.reloadData()
            
            if self.similiarArtists?.count == 0 {
                similarArtistCell.noContentLabel.hidden = false
                similarArtistCell.noContentLabel.text = "Start playing some music to see recommended Artists"
            } else {
                similarArtistCell.noContentLabel.hidden = true
            }
            
            if self.similiarArtists?.count > 0 {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.similarArtistCell.collectionView.scrollToItemAtIndexPath(NSIndexPath(forRow: 0, inSection: 0),
                        atScrollPosition: .Left, animated: true)
                })
            }
            
            return similarArtistCell
        case .RecentPlaylists:
            
            let playlist = self.recentPlaylistsController!.objectAtIndexPath(NSIndexPath(forRow: indexPath.row, inSection: 0)) as Playlist
            
            var cell = tableView.dequeueReusableCellWithIdentifier("PlaylistCell") as PlaylistCell
            cell.updateWithPlaylist(playlist)
            
            return cell
        case .RecentArtists:
            recentArtistCell.collectionView.delegate = self
            recentArtistCell.collectionView.dataSource = self
            
            recentArtistCell.similiarActivityIndicator.stopAnimating()
            
            let nib = UINib(nibName: "SimiliarArtistCollectionViewCell", bundle: nil)
            recentArtistCell.collectionView.registerNib(nib, forCellWithReuseIdentifier: "SimiliarArtistCell")
            
            recentArtistCell.collectionView.reloadData()
            
            return recentArtistCell
        default:
            let song = self.recentSongs?[indexPath.row] as NSDictionary
            songCell.updateWithSongData(song)
            songCell.accessoryType = .DisclosureIndicator
            
            return songCell
        }
    }
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            return 0
        }
        return 30
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if let sectionType = HomeSectionType(rawValue: indexPath.section) {
            switch sectionType {
            case .NowPlaying:
                if let item = self.nowPlayingCell.playerController.nowPlayingItem {
                    return 81
                }
                return 0
            case .RelatedArtists: return 124
            case .RecentArtists: return 124
            default: return 55
            }
        }
        
        return 0
    }
    
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if let sectionType = HomeSectionType(rawValue: section) {
            let header = tableView.dequeueReusableHeaderFooterViewWithIdentifier("Header") as ArtistsHeader
            
            switch sectionType {
            case .NowPlaying:
                header.infoLabel.text = ""
            case .RecentArtists:
                header.infoLabel.text = "Recent Artists"
            case .RecentSongs:
                header.infoLabel.text = "Recent Songs"
            case .RelatedArtists:
                header.infoLabel.text = "Recommended Artists"
            default:
                header.infoLabel.text = "Recent Playlists"
            }
            
            return header
        }
       
        return nil
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let sectionType = HomeSectionType(rawValue: indexPath.section)!
        switch sectionType {
        case .RelatedArtists: break
        case .NowPlaying:
            self.presentNowPlayViewController()
        case .RecentPlaylists:
            let playlist = self.recentPlaylistsController!.objectAtIndexPath(NSIndexPath(forRow: indexPath.row, inSection: 0)) as Playlist
            let playlistsSongs = PlaylistSongsViewController(playlist: playlist)
            self.navigationController?.pushViewController(playlistsSongs, animated: true)
        case .RecentSongs:
            let songData = self.recentSongs?[indexPath.row] as NSDictionary
            DataManager.manager.datastore.songForSongName(songData.objectForKey("title") as NSString, artist: songData.objectForKey("artist") as NSString, completion: { (song) -> () in
                if let playingSong = song {
                    MediaSession.sharedSession.fetchSongsCollection({ (collection) -> () in
                        self.navigationController!.pushViewController(NowPlayingViewController(song: playingSong, collection: collection), animated: true)
                    })
                }
            })
        default: break
        }
        
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    // MARK: UICollectionViewDataSource
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == self.recentArtistCell.collectionView {
            return self.recentArtistSongs?.count ?? 0
        }
        return self.similiarArtists?.count ?? 0
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        var cell = collectionView.dequeueReusableCellWithReuseIdentifier("SimiliarArtistCell",
            forIndexPath: indexPath) as SimiliarArtistCollectionViewCell
        
        if collectionView == self.recentArtistCell.collectionView {
            let song = self.recentArtistSongs?[indexPath.row] as NSDictionary
            cell.updateWithSongData(song, forArtist: true)
        } else {
            if let artist = similiarArtists?[indexPath.row] as? LastFmArtist {
                cell.updateWithArtist(artist)
            }
        }
        
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        if collectionView == self.recentArtistCell.collectionView {
            let song = self.recentArtistSongs?[indexPath.row] as NSDictionary
            if let artist = DataManager.manager.datastore.artistForSongData(song: song) {
                let artistAlbums = ArtistAlbumsViewController(artist: artist)
                self.navigationController?.pushViewController(artistAlbums, animated: true)
            }
        } else {
            if let artist = self.similiarArtists?[indexPath.row] as? LastFmArtist {
                let nowPlaying = NowPlayingInfoViewController(artist: artist.name, isForSimiliarArtist: true)
                self.navigationController?.pushViewController(nowPlaying, animated: true)
            }
        }
    }
}