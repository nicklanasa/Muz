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
import CoreLocation
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


enum HomeSectionType: NSInteger {
    case nowPlaying
    case recentArtists
    case recentPlaylists
    case recentSongs
}

class HomeViewController: RootViewController,
UITableViewDataSource,
UITableViewDelegate,
NSFetchedResultsControllerDelegate,
UICollectionViewDelegate,
UICollectionViewDataSource {
    
    var locationManager: CLLocationManager = CLLocationManager()
    
    @IBOutlet weak var tableView: UITableView!
    
    fileprivate var recentArtistSongs: NSArray? {
        didSet {
            self.tableView.reloadData()
        }
    }
    fileprivate var recentSongs: NSArray? {
        didSet {
            self.tableView.reloadData()
        }
    }
    
    var similarArtistCell: LastFmSimilarArtistTableCell!
    var recentArtistCell: LastFmSimilarArtistTableCell!
    var nowPlayingCell: NowPlayingTableViewCell!
    var events: [AnyObject]? {
        didSet {
            self.tableView.reloadData()
        }
    }

    fileprivate var recentPlaylistsController: NSFetchedResultsController<NSFetchRequestResult>?
    
    init() {
        super.init(nibName: "HomeViewController", bundle: nil)
        
        self.tabBarItem = UITabBarItem(title: nil,
            image: UIImage(named: "headphones"),
            selectedImage: UIImage(named: "headphones"))

        
        self.tabBarItem.imageInsets = UIEdgeInsetsMake(6, 0, -6, 0)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.screenName = "Dashboard"
        super.viewWillAppear(animated)
        
        self.recentArtistSongs = DataManager.manager.datastore.distinctArtistSongsWithSortKey("lastPlayedDate", limit: 25, ascending: false)
        self.recentSongs = DataManager.manager.datastore.recentlyPlayedSongs(limit: 5)
        
        self.recentPlaylistsController = DataManager.manager.datastore.playlistsControllerWithSortKey(sortKey: "modifiedDate",
            ascending: false,
            limit: 3,
            sectionNameKeyPath: nil)
        self.recentPlaylistsController!.delegate = self
        
        let nowPlayingCellNib = UINib(nibName: "NowPlayingTableViewCell", bundle: nil)
        nowPlayingCell = nowPlayingCellNib.instantiate(withOwner: self, options: nil)[0] as? NowPlayingTableViewCell
        
        self.fetchHomeData()
    }
    
    func fetchHomeData() {
        do {
            try self.recentPlaylistsController!.performFetch()
        } catch {}
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.register(UINib(nibName: "SongCell", bundle: nil), forCellReuseIdentifier: "SongCell")
        self.tableView.register(UINib(nibName: "PlaylistCell", bundle: nil), forCellReuseIdentifier: "PlaylistCell")
        self.tableView.register(UINib(nibName: "AddPlaylistCell", bundle: nil), forCellReuseIdentifier: "AddPlaylistCell")
        self.tableView.register(UINib(nibName: "ArtistsHeader", bundle: nil), forHeaderFooterViewReuseIdentifier: "Header")
        
        let recentArtistCellNib = UINib(nibName: "LastFmSimilarArtistTableCell", bundle: nil)
        recentArtistCell = recentArtistCellNib.instantiate(withOwner: self, options: nil)[0] as? LastFmSimilarArtistTableCell
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "search"),
            style: .plain,
            target: self,
            action: #selector(HomeViewController.showSearch))
    }
    
    func showSearch() {
        self.presentSearchOverlayController(SearchOverlayController(), blurredController: self)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 4
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.recentArtistSongs?.count > 0 && self.recentPlaylistsController != nil {
            if let sectionType = HomeSectionType(rawValue: section) {
                var controller: NSFetchedResultsController<NSFetchRequestResult>!
                switch sectionType {
                case .recentSongs:
                    return self.recentSongs?.count ?? 0
                case .recentPlaylists:
                    controller = self.recentPlaylistsController
                    
                    if let numberOfRowsInSection = controller.sections?[0].numberOfObjects {
                        return numberOfRowsInSection + 1
                    } else {
                        return 1
                    }
                default:
                    return 1
                }
            }
        }
        
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let sectionType = HomeSectionType(rawValue: indexPath.section)!
        
        let songCell = tableView.dequeueReusableCell(withIdentifier: "SongCell") as! SongCell
        
        switch sectionType {
        case .nowPlaying:
            return nowPlayingCell
        case .recentPlaylists:
            
            if indexPath.row == 0 {
                return tableView.dequeueReusableCell(withIdentifier: "AddPlaylistCell") as! AddPlaylistCell
            }
            
            let playlist = self.recentPlaylistsController!.object(at: IndexPath(row: indexPath.row - 1, section: 0)) as! Playlist
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "PlaylistCell") as! PlaylistCell
            cell.updateWithPlaylist(playlist)
            
            return cell
        case .recentArtists:
            recentArtistCell.collectionView.delegate = self
            recentArtistCell.collectionView.dataSource = self
            
            recentArtistCell.similiarActivityIndicator.stopAnimating()
            
            let nib = UINib(nibName: "SimiliarArtistCollectionViewCell", bundle: nil)
            recentArtistCell.collectionView.register(nib, forCellWithReuseIdentifier: "SimiliarArtistCell")
            
            recentArtistCell.collectionView.reloadData()
            
            return recentArtistCell
        default:
            let song = self.recentSongs?[indexPath.row] as! NSDictionary
            songCell.updateWithSongData(song)            
            return songCell
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            return 0
        }
        return 30
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if let sectionType = HomeSectionType(rawValue: indexPath.section) {
            switch sectionType {
            case .nowPlaying:
                if let _ = self.nowPlayingCell.playerController.nowPlayingItem {
                    return 81
                }
                return 0
            case .recentArtists: return 124
            default: return 65
            }
        }
        
        return 0
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if let sectionType = HomeSectionType(rawValue: section) {
            let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: "Header") as! ArtistsHeader
            
            switch sectionType {
            case .nowPlaying:
                header.infoLabel.text = ""
            case .recentArtists:
                header.infoLabel.text = "Recent Artists"
            case .recentSongs:
                header.infoLabel.text = "Recent Songs"
            default:
                header.infoLabel.text = "Recent Playlists"
            }
            
            return header
        }
       
        return nil
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let sectionType = HomeSectionType(rawValue: indexPath.section)!
        switch sectionType {
        case .nowPlaying:
            self.presentNowPlayViewController()
        case .recentPlaylists:
            if indexPath.row == 0 {
                self.presentModalOverlayController(CreatePlaylistOverlay(), blurredController: self)
            } else {
                let playlist = self.recentPlaylistsController!.object(at: IndexPath(row: indexPath.row-1, section: 0)) as! Playlist
                let playlistsSongs = PlaylistSongsViewController(playlist: playlist)
                self.navigationController?.pushViewController(playlistsSongs, animated: true)
            }
        case .recentSongs:
            let songData = self.recentSongs?[indexPath.row] as! NSDictionary
            DataManager.manager.datastore.songForSongName(songData.object(forKey: "title") as! String, artist: songData.object(forKey: "artist") as! String, completion: { (song) -> () in
                if let playingSong = song {
                    MediaSession.sharedSession.fetchSongsCollection({ (collection) -> () in
                        if collection != nil {
                            self.navigationController!.pushViewController(NowPlayingViewController(song: playingSong, collection: collection!), animated: true)
                        } else {
                            DispatchQueue.main.async(execute: { () -> Void in
                                UIAlertView(title: "Error!",
                                    message: "Unable to get collection!",
                                    delegate: self,
                                    cancelButtonTitle: "Ok").show()
                            })
                        }
                    })
                }
            })
        default: break
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    // MARK: UICollectionViewDataSource
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.recentArtistSongs?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SimiliarArtistCell",
                                                                         for: indexPath) as! SimiliarArtistCollectionViewCell
        let song = self.recentArtistSongs?[indexPath.row] as! NSDictionary
        cell.updateWithSongData(song, forArtist: true)
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let song = self.recentArtistSongs?[indexPath.row] as! NSDictionary
        if let artist = DataManager.manager.datastore.artistForSongData(song: song) {
            let artistAlbums = ArtistAlbumsViewController(artist: artist)
            self.navigationController?.pushViewController(artistAlbums, animated: true)
        }
    }
}
