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

enum HomeSectionType: NSInteger {
    case NowPlaying
    case UpcomingEvents
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
UICollectionViewDataSource, CLLocationManagerDelegate {
    
    var locationManager: CLLocationManager = CLLocationManager()
    
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
    var lastFmEventCell: LastFmEventCell!
    var events: [AnyObject]? {
        didSet {
            self.tableView.reloadData()
        }
    }

    private var recentPlaylistsController: NSFetchedResultsController?
    
    init() {
        super.init(nibName: "HomeViewController", bundle: nil)
        
        self.tabBarItem = UITabBarItem(title: nil,
            image: UIImage(named: "headphones"),
            selectedImage: UIImage(named: "headphones"))
        
        self.tabBarItem.imageInsets = UIEdgeInsetsMake(6, 0, -6, 0)
        
        self.locationManager.delegate = self
        self.locationManager.requestAlwaysAuthorization()
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewWillAppear(animated: Bool) {
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
        nowPlayingCell = nowPlayingCellNib.instantiateWithOwner(self, options: nil)[0] as? NowPlayingTableViewCell
        
        let lastFmEventCellNib = UINib(nibName: "LastFmEventCell", bundle: nil)
        lastFmEventCell = lastFmEventCellNib.instantiateWithOwner(self, options: nil)[0] as? LastFmEventCell
        
        self.fetchHomeData()
        
        self.locationManager.startUpdatingLocation()
    }
    
    func fetchHomeData() {
        var recentPlaylistsError: NSError?
        var recentSongsError: NSError?
        if self.recentPlaylistsController!.performFetch(&recentPlaylistsError) {
            if self.recentArtistSongs?.count > 0 {
                if let song = self.recentArtistSongs?[0] as? NSDictionary {
                    var similiarArtistLastFmRequest = LastFmSimiliarArtistsRequest(artist: song.objectForKey("artist") as! String)
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
        self.tableView.registerNib(UINib(nibName: "AddPlaylistCell", bundle: nil), forCellReuseIdentifier: "AddPlaylistCell")
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
        return 6
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
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let sectionType = HomeSectionType(rawValue: indexPath.section)!
        
        var songCell = tableView.dequeueReusableCellWithIdentifier("SongCell") as! SongCell
        
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
            
            if indexPath.row == 0 {
                return tableView.dequeueReusableCellWithIdentifier("AddPlaylistCell") as! AddPlaylistCell
            }
            
            let playlist = self.recentPlaylistsController!.objectAtIndexPath(NSIndexPath(forRow: indexPath.row - 1, inSection: 0)) as! Playlist
            
            var cell = tableView.dequeueReusableCellWithIdentifier("PlaylistCell") as! PlaylistCell
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
        case .UpcomingEvents:
            let nib = UINib(nibName: "LastFmEventInfoCell", bundle: nil)
            lastFmEventCell.collectionView.registerNib(nib, forCellWithReuseIdentifier: "LastFmEventInfoCell")
            
            lastFmEventCell.collectionView.delegate = self
            lastFmEventCell.collectionView.dataSource = self
            
            lastFmEventCell.upcomingEventsLabel.hidden = true
            lastFmEventCell.setNeedsDisplay()
            
            lastFmEventCell.updateWithEvents(self.events)
            
            return lastFmEventCell
        default:
            let song = self.recentSongs?[indexPath.row] as! NSDictionary
            songCell.updateWithSongData(song)            
            return songCell
        }
    }
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0{
            return 0
        }
    
        return 30
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if let sectionType = HomeSectionType(rawValue: indexPath.section) {
            switch sectionType {
            case .UpcomingEvents:
                if self.events?.count > 0 {
                    return 145
                }
                return 0
            case .NowPlaying:
                if let item = self.nowPlayingCell.playerController.nowPlayingItem {
                    return 81
                }
                return 0
            case .RelatedArtists: return 124
            case .RecentArtists: return 124
            default: return 65
            }
        }
        
        return 0
    }
    
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if let sectionType = HomeSectionType(rawValue: section) {
            let header = tableView.dequeueReusableHeaderFooterViewWithIdentifier("Header") as! ArtistsHeader
            
            switch sectionType {
            case .UpcomingEvents:
                header.infoLabel.text = "Local Upcoming Events"
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
            LocalyticsSession.shared().tagEvent("Dashboard NowPlaying Cell Tapped.")
        case .RecentPlaylists:
            if indexPath.row == 0 {
                LocalyticsSession.shared().tagEvent("Dashboard New Playlist tapped.")
                self.presentModalOverlayController(CreatePlaylistOverlay(), blurredController: self)
            } else {
                LocalyticsSession.shared().tagEvent("Recent Playing tapped.")
                let playlist = self.recentPlaylistsController!.objectAtIndexPath(NSIndexPath(forRow: indexPath.row-1, inSection: 0)) as! Playlist
                let playlistsSongs = PlaylistSongsViewController(playlist: playlist)
                self.navigationController?.pushViewController(playlistsSongs, animated: true)
            }
        case .RecentSongs:
            let songData = self.recentSongs?[indexPath.row] as! NSDictionary
            DataManager.manager.datastore.songForSongName(songData.objectForKey("title") as! String, artist: songData.objectForKey("artist") as! String, completion: { (song) -> () in
                if let playingSong = song {
                    MediaSession.sharedSession.fetchSongsCollection({ (collection) -> () in
                        LocalyticsSession.shared().tagEvent("Recent Song tapped.")
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
        } else if collectionView == lastFmEventCell?.collectionView {
            return self.events?.count ?? 0
        }
        return self.similiarArtists?.count ?? 0
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
    
        if collectionView == self.recentArtistCell.collectionView {
            var cell = collectionView.dequeueReusableCellWithReuseIdentifier("SimiliarArtistCell",
                forIndexPath: indexPath) as! SimiliarArtistCollectionViewCell
            let song = self.recentArtistSongs?[indexPath.row] as! NSDictionary
            cell.updateWithSongData(song, forArtist: true)
            
            return cell
        } else if collectionView == lastFmEventCell?.collectionView {
            var cell = collectionView.dequeueReusableCellWithReuseIdentifier("LastFmEventInfoCell",
                forIndexPath: indexPath) as! LastFmEventInfoCell
            
            if let event = events?[indexPath.row] as? LastFmEvent {
                cell.updateWithGeoEvent(event)
            }
            
            return cell
        } else {
            var cell = collectionView.dequeueReusableCellWithReuseIdentifier("SimiliarArtistCell",
                forIndexPath: indexPath) as! SimiliarArtistCollectionViewCell
            if let artist = similiarArtists?[indexPath.row] as? LastFmArtist {
                cell.updateWithArtist(artist)
            }
            
            return cell
        }
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        if collectionView == self.recentArtistCell.collectionView {
            let song = self.recentArtistSongs?[indexPath.row] as! NSDictionary
            if let artist = DataManager.manager.datastore.artistForSongData(song: song) {
                LocalyticsSession.shared().tagEvent("Recent Song tapped.")
                let artistAlbums = ArtistAlbumsViewController(artist: artist)
                self.navigationController?.pushViewController(artistAlbums, animated: true)
            }
        } else if collectionView == lastFmEventCell?.collectionView {
            if let event = self.events?[indexPath.row] as? LastFmEvent {
                LocalyticsSession.shared().tagEvent("Event tapped.")
                let eventController = LastFmEventInfoController(event: event)
                self.navigationController?.pushViewController(eventController, animated: true)
            }
        } else {
            if let artist = self.similiarArtists?[indexPath.row] as? LastFmArtist {
                LocalyticsSession.shared().tagEvent("Recent Artist tapped.")
                let nowPlaying = NowPlayingInfoViewController(artist: artist.name, isForSimiliarArtist: true)
                self.navigationController?.pushViewController(nowPlaying, animated: true)
            }
        }
    }
    
    func locationManager(manager: CLLocationManager!, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        println("didChangeAuthorizationStatus")
        
        switch status {
        case .NotDetermined:
            println(".NotDetermined")
            LocalyticsSession.shared().tagEvent("Denied Location")
            break
            
        case .AuthorizedAlways:
            println(".Authorized")
            self.locationManager.startUpdatingLocation()
            LocalyticsSession.shared().tagEvent("Allowed Location")
            break
            
        case .AuthorizedWhenInUse:
            println(".Authorized")
            self.locationManager.startUpdatingLocation()
            LocalyticsSession.shared().tagEvent("Allowed Location")
            break
            
        case .Denied:
            println(".Denied")
            LocalyticsSession.shared().tagEvent("Denied Location")
            break
            
        default:
            println("Unhandled authorization status")
            break
            
        }
    }
    
    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
        
        let location = locations.last as! CLLocation
        CLGeocoder().reverseGeocodeLocation(location, completionHandler: { (placemarks, error) -> Void in
            if error != nil {
                print(error)
            } else {
                if placemarks.count > 0 {
                    var placemark = placemarks.first as! CLPlacemark
                    var cityState: String = "\(placemark.locality), \(placemark.administrativeArea)"
                    LastFmGeoEventsRequest.sharedRequest.getEvents(cityState, completion: { (events, error) -> () in
                        self.events = events
                        self.locationManager.stopUpdatingLocation()
                    })
                }
            }
        })
        
    }
}