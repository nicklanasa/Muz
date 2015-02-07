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

    private var recentPlaylistsController: NSFetchedResultsController?
    
    private var recentSongsController: NSFetchedResultsController?
    
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
        
        self.recentSongsController = DataManager.manager.datastore.songsControllerWithSortKey("lastPlayedDate",
            limit: 3,
            ascending: false,
            sectionNameKeyPath: nil)
        self.recentSongsController!.delegate = self
        
        self.recentPlaylistsController = DataManager.manager.datastore.playlistsControllerWithSortKey(sortKey: "modifiedDate",
            ascending: true,
            limit: 3,
            sectionNameKeyPath: nil)
        self.recentPlaylistsController!.delegate = self
        
        self.fetchHomeData()
    }
    
    override func viewDidDisappear(animated: Bool) {
//        self.recentSongsController = nil
//        self.recentPlaylistsController = nil
    }
    
    // MARK: Sectors NSFetchedResultsControllerDelegate
    
    func controllerWillChangeContent(controller: NSFetchedResultsController)
    {
        self.tableView.beginUpdates()
    }
    
    func controller(controller: NSFetchedResultsController,
        didChangeObject anObject: AnyObject,
        atIndexPath indexPath: NSIndexPath?,
        forChangeType type: NSFetchedResultsChangeType,
        newIndexPath: NSIndexPath?)
    {
        var tableView = self.tableView
        var indexPaths:[NSIndexPath] = [NSIndexPath]()
        switch type {
            
        case .Insert:
            indexPaths.append(newIndexPath!)
            tableView.insertRowsAtIndexPaths(indexPaths, withRowAnimation: .Fade)
            
        case .Delete:
            indexPaths.append(indexPath!)
            tableView.deleteRowsAtIndexPaths(indexPaths, withRowAnimation: .Fade)
            
        case .Update:
            indexPaths.append(indexPath!)
            tableView.reloadRowsAtIndexPaths(indexPaths, withRowAnimation: .Fade)
            
        case .Move:
            indexPaths.append(indexPath!)
            tableView.deleteRowsAtIndexPaths(indexPaths, withRowAnimation: .Fade)
            indexPaths.removeAtIndex(0)
            indexPaths.append(newIndexPath!)
            tableView.insertRowsAtIndexPaths(indexPaths, withRowAnimation: .Fade)
        }
    }
    
    func controller(controller: NSFetchedResultsController,
        didChangeSection sectionInfo: NSFetchedResultsSectionInfo,
        atIndex sectionIndex: Int,
        forChangeType type: NSFetchedResultsChangeType)
    {
        switch type {
            
        case .Insert:
            self.tableView.insertSections(NSIndexSet(index: sectionIndex),
                withRowAnimation: .Fade)
            
        case .Delete:
            self.tableView.deleteSections(NSIndexSet(index: sectionIndex),
                withRowAnimation: .Fade)
            
        case .Update, .Move: println("Move or delete called in didChangeSection")
        }
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController)
    {
        self.tableView.endUpdates()
    }
    
    func fetchHomeData() {
        var recentPlaylistsError: NSError?
        var recentSongsError: NSError?
        if self.recentPlaylistsController!.performFetch(&recentPlaylistsError) {
            if self.recentSongsController!.performFetch(&recentSongsError) {
                if self.recentSongsController!.sections?.count > 0 {
                    if self.recentSongsController!.sections?[0].numberOfObjects > 0 {
                        if let song = self.recentSongsController!.objectAtIndexPath(NSIndexPath(forRow: 0, inSection: 0)) as? Song {
                            var similiarArtistLastFmRequest = LastFmSimiliarArtistsRequest(artist: song.artist)
                            similiarArtistLastFmRequest.delegate = self
                            similiarArtistLastFmRequest.sendURLRequest()
                        }
                    }
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
        
        var controller = self.recentSongsController!
        switch sectionType {
        case .RelatedArtists:
            similarArtistCell.collectionView.delegate = self
            similarArtistCell.collectionView.dataSource = self
            
            let nib = UINib(nibName: "SimiliarArtistCollectionViewCell", bundle: nil)
            similarArtistCell.collectionView.registerNib(nib, forCellWithReuseIdentifier: "SimiliarArtistCell")
            
            similarArtistCell.collectionView.reloadData()
            
            return similarArtistCell
        case .RecentPlaylists:
            controller = self.recentPlaylistsController!
            
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
        
        cell.accessoryType = .DisclosureIndicator
        
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
            let playlist = self.recentPlaylistsController!.objectAtIndexPath(NSIndexPath(forRow: indexPath.row, inSection: 0)) as Playlist
            let playlistsSongs = PlaylistSongsViewController(playlist: playlist)
            self.navigationController?.pushViewController(playlistsSongs, animated: true)
        case .RecentArtists:
            let song = self.recentSongsController!.objectAtIndexPath(NSIndexPath(forRow: indexPath.row, inSection: 0)) as Song
            if let artist = DataManager.manager.datastore.artistForSong(song: song) {
                let artistAlbums = ArtistAlbumsViewController(artist: artist)
                self.navigationController?.pushViewController(artistAlbums, animated: true)
            }
        default:
            let song = self.recentSongsController!.objectAtIndexPath(NSIndexPath(forRow: indexPath.row, inSection: 0)) as Song
            DataManager.manager.fetchSongsCollection({ (collection, error) -> () in
                self.presentNowPlayViewController(song, collection: collection)
            })
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