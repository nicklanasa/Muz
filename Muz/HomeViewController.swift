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
    case RecentPlaylists
    case RecentArtists
    case RecentSongs
    case RelatedArtists
}

class HomeViewController: RootViewController,
UITableViewDataSource, UITableViewDelegate,
NSFetchedResultsControllerDelegate,
LastFmSimiliarArtistsRequestDelegate,
UICollectionViewDelegate,
UICollectionViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    
    private var similiarArtists: [AnyObject]?
    
    var similarArtistCell: LastFmSimilarArtistTableCell!

    private lazy var recentPlaylistsController: NSFetchedResultsController = {
        let controller = MediaSession.sharedSession.dataManager.datastore.playlistsControllerWithSortKey(sortKey: "modifiedDate", ascending: false, sectionNameKeyPath: nil)
        controller.delegate = self
        return controller
    }()
    
    private lazy var recentSongsController: NSFetchedResultsController = {
        let controller = DataManager.manager.datastore.songsControllerWithSortKey("lastPlayedDate",
            ascending: false,
            sectionNameKeyPath: nil)
        controller.delegate = self
        return controller
    }()
    
    override init() {
        super.init(nibName: "HomeViewController", bundle: nil)
        
        self.tabBarItem = UITabBarItem(title: nil,
            image: UIImage(named: "858-line-chart"),
            selectedImage: UIImage(named: "858-line-chart"))
        
        self.tabBarItem.imageInsets = UIEdgeInsetsMake(6, 0, -6, 0)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.fetchHomeData()
    }
    
    func fetchHomeData() {
        var recentPlaylistsError: NSError?
        var recentSongsError: NSError?
        if self.recentPlaylistsController.performFetch(&recentPlaylistsError) {
            if self.recentSongsController.performFetch(&recentSongsError) {
                if let song = self.recentSongsController.objectAtIndexPath(NSIndexPath(forRow: 0, inSection: 0)) as? Song {
                    var similiarArtistLastFmRequest = LastFmSimiliarArtistsRequest(artist: song.artist)
                    similiarArtistLastFmRequest.delegate = self
                    similiarArtistLastFmRequest.sendURLRequest()
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.registerNib(UINib(nibName: "SongCell", bundle: nil), forCellReuseIdentifier: "Cell")
        self.tableView.registerNib(UINib(nibName: "PlaylistCell", bundle: nil), forCellReuseIdentifier: "PlaylistCell")
        self.tableView.registerNib(UINib(nibName: "ArtistsHeader", bundle: nil), forHeaderFooterViewReuseIdentifier: "Header")
        
        let similarArtistCellNib = UINib(nibName: "LastFmSimilarArtistTableCell", bundle: nil)
        similarArtistCell = similarArtistCellNib.instantiateWithOwner(self, options: nil)[0] as? LastFmSimilarArtistTableCell
        
        self.navigationItem.title = "Charts"
    }
    
    func lastFmSimiliarArtistsRequestDidComplete(request: LastFmSimiliarArtistsRequest, didCompleteWithLastFmArtists artists: [AnyObject]?) {
        self.similiarArtists = artists
        similarArtistCell.similiarActivityIndicator.stopAnimating()
        self.tableView.reloadData()
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 4
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let sectionType = HomeSectionType(rawValue: section) {
            var controller: NSFetchedResultsController!
            switch sectionType {
            case .RelatedArtists: return 1
            case .RecentPlaylists:
                controller = self.recentPlaylistsController
            default:
                controller = self.recentSongsController
            }
            
            if let numberOfRowsInSection = controller.sections?[0].numberOfObjects {
                return numberOfRowsInSection
            } else {
                return 0
            }
        }
        
        return 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let sectionType = HomeSectionType(rawValue: indexPath.section)!
        
        var cell = tableView.dequeueReusableCellWithIdentifier("Cell") as SongCell
        
        var controller = self.recentSongsController
        switch sectionType {
        case .RelatedArtists:
            similarArtistCell.collectionView.delegate = self
            similarArtistCell.collectionView.dataSource = self
            
            let nib = UINib(nibName: "SimiliarArtistCollectionViewCell", bundle: nil)
            similarArtistCell.collectionView.registerNib(nib, forCellWithReuseIdentifier: "SimiliarArtistCell")
            
            similarArtistCell.collectionView.reloadData()
            
            return similarArtistCell
        case .RecentPlaylists:
            controller = self.recentPlaylistsController
            
            let playlist = controller.objectAtIndexPath(NSIndexPath(forRow: indexPath.row, inSection: 0)) as Playlist
            
            var cell = tableView.dequeueReusableCellWithIdentifier("PlaylistCell") as PlaylistCell
            cell.updateWithPlaylist(playlist)
            
            return cell
        case .RecentArtists:
            let song = controller.objectAtIndexPath(NSIndexPath(forRow: indexPath.row, inSection: 0)) as Song
            cell.updateWithSong(song, forArtist: true)
        default:
            let song = controller.objectAtIndexPath(NSIndexPath(forRow: indexPath.row, inSection: 0)) as Song
            cell.updateWithSong(song)
        }
        
        return cell
    }
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 30
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if let sectionType = HomeSectionType(rawValue: indexPath.section) {
            switch sectionType {
            case .RelatedArtists: return 124
            default: return 55
            }
        }
        
        return 0
    }
    
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if let sectionType = HomeSectionType(rawValue: section) {
            let header = tableView.dequeueReusableHeaderFooterViewWithIdentifier("Header") as ArtistsHeader
            
            switch sectionType {
            case .RecentArtists:
                header.infoLabel.text = "Recent Artists"
            case .RecentSongs:
                header.infoLabel.text = "Recent Songs"
            case .RelatedArtists:
                header.infoLabel.text = "Related Artists"
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
        case .RecentPlaylists:
            let playlist = self.recentPlaylistsController.objectAtIndexPath(NSIndexPath(forRow: indexPath.row, inSection: 0)) as Playlist
            let playlistsSongs = PlaylistSongsViewController(playlist: playlist)
            self.navigationController?.pushViewController(playlistsSongs, animated: true)
        case .RecentArtists:
            let song = self.recentSongsController.objectAtIndexPath(NSIndexPath(forRow: indexPath.row, inSection: 0)) as Song
            if let artist = DataManager.manager.datastore.artistForSong(song: song) {
                let artistAlbums = ArtistAlbumsViewController(artist: artist)
                self.navigationController?.pushViewController(artistAlbums, animated: true)
            }
        default:
            let song = self.recentSongsController.objectAtIndexPath(NSIndexPath(forRow: indexPath.row, inSection: 0)) as Song
            self.presentNowPlayViewController(song, collection: MPMediaItemCollection(items: [song]))
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
        if let artist = self.similiarArtists?[indexPath.row] as? LastFmArtist {
            let nowPlaying = NowPlayingInfoViewController(artist: artist, isForSimiliarArtist: true)
            self.navigationController?.pushViewController(nowPlaying, animated: true)
        }
    }
}