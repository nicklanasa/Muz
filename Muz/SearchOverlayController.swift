//
//  SearchOverlayController.swift
//  Muz
//
//  Created by Nickolas Lanasa on 3/15/15.
//  Copyright (c) 2015 Nytek Productions. All rights reserved.
//

import Foundation
import UIKit
import CoreData

enum SearchResultsSection: Int {
    case SearchSwitch
    case Artists
    case Albums
    case Tracks
}

class SearchOverlayController: OverlayController,
UITableViewDelegate,
UITableViewDataSource,
UISearchBarDelegate,
UISearchDisplayDelegate,
SearchSwitchCellDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var cancelButton: UIButton!
    
    var recentSongs: NSArray?
    
    var searchSwitchCell: SearchSwitchCell!
    
    var artists: NSArray? {
        didSet {
            self.searchDisplayController?.searchResultsTableView.reloadData()
        }
    }
    
    var albums: NSArray? {
        didSet {
            self.searchDisplayController?.searchResultsTableView.reloadData()
        }
    }
    
    var tracks: NSArray? {
        didSet {
            self.searchDisplayController?.searchResultsTableView.reloadData()
        }
    }
    
    lazy var artistsController: NSFetchedResultsController = {
        var controller = DataManager.manager.datastore.artistsController(nil,
            sortKey: "name",
            ascending: true,
            sectionNameKeyPath: nil)
        return controller
    }()
    
    lazy var albumsController: NSFetchedResultsController = {
        var controller = DataManager.manager.datastore.artistsController(nil,
            sortKey: "name",
            ascending: true,
            sectionNameKeyPath: nil)
        return controller
    }()
    
    lazy var songsController: NSFetchedResultsController = {
        var controller = DataManager.manager.datastore.artistsController(nil,
            sortKey: "name",
            ascending: true,
            sectionNameKeyPath: nil)
        return controller
    }()
    
    override init() {
        super.init(nibName: "SearchOverlayController", bundle: nil)
    }
    
    required override init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewWillAppear(animated: Bool) {
        self.overlayScreenName = "Search"
        super.viewWillAppear(animated)
        
        self.searchDisplayController?.setActive(true, animated: true)
        self.searchDisplayController?.searchBar.becomeFirstResponder()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.registerNib(UINib(nibName: "RecommendedSearchCell", bundle: nil),
            forCellReuseIdentifier: "RecommendedSearchCell")
        tableView.registerNib(UINib(nibName: "ArtistsHeader", bundle: nil),
            forHeaderFooterViewReuseIdentifier: "Header")
        
        searchDisplayController?.searchResultsTableView.registerNib(UINib(nibName: "ArtistCell", bundle: nil),
            forCellReuseIdentifier: "ArtistCell")
        searchDisplayController?.searchResultsTableView.registerNib(UINib(nibName: "TopAlbumCell", bundle: nil),
            forCellReuseIdentifier: "AblumCell")
        searchDisplayController?.searchResultsTableView.registerNib(UINib(nibName: "ArtistsHeader", bundle: nil),
            forHeaderFooterViewReuseIdentifier: "Header")
        
        searchDisplayController?.searchResultsTableView.backgroundColor = UIColor.clearColor()
        searchDisplayController?.searchResultsTableView.separatorStyle = .None
        
        self.recentSongs = DataManager.manager.datastore.distinctArtistSongsWithSortKey("lastPlayedDate",
            limit: 10,
            ascending: false)
        
        let searchSwitchCellNib = UINib(nibName: "SearchSwitchCell", bundle: nil)
        searchSwitchCell = searchSwitchCellNib.instantiateWithOwner(self, options: nil)[0] as? SearchSwitchCell
        searchSwitchCell.delegate = self
    }
    
    func dismiss() {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == self.searchDisplayController?.searchResultsTableView {
            if let searchSection = SearchResultsSection(rawValue: section) {
                switch searchSection {
                case .SearchSwitch: return 1
                case .Artists: return self.artists?.count ?? 0
                case .Albums: return self.albums?.count ?? 0
                default: return self.tracks?.count ?? 0
                }
            }
            return 0
        }
        
        return self.recentSongs?.count ?? 0
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if tableView == self.searchDisplayController?.searchResultsTableView {
            return 4
        }
        
        return 1
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if tableView == self.searchDisplayController?.searchResultsTableView {
            return 65
        }
        return 40
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        if tableView == self.searchDisplayController?.searchResultsTableView {
            
            let cell = searchDisplayController?.searchResultsTableView.dequeueReusableCellWithIdentifier("AblumCell",
                forIndexPath: indexPath) as TopAlbumCell
            
            cell.accessoryType = .None
            cell.songImageView.image = nil
            cell.songLabel.text = ""
            cell.infoLabel.text = ""
            cell.buyButton.hidden = true

            let searchSection = SearchResultsSection(rawValue: indexPath.section)!
            switch searchSection {
            case .SearchSwitch:
                cell.songImageView.image = nil
                return self.searchSwitchCell
            case .Artists:
                let artist = self.artists?[indexPath.row] as NSDictionary
                cell.updateWithArtist(artist)
                cell.buyButton.hidden = true
                cell.accessoryType = .DisclosureIndicator
                
                return cell
            case .Albums:
                let album = self.albums?[indexPath.row] as NSDictionary
                cell.updateWithAlbum(album)
                cell.buyButton.hidden = false
                cell.buyButton.tag = indexPath.row
                if let albumPrice = album["collectionPrice"] as? NSNumber {
                    if let albumLink = album["collectionViewUrl"] as? String {
                        cell.buyButton.setTitle("$\(albumPrice.description)", forState: .Normal)
                        cell.buyButton.addTarget(self, action: "openAlbumLink:", forControlEvents: .TouchUpInside)
                    }
                }
                
                return cell
            default:
                let topTrack = self.tracks?[indexPath.row] as NSDictionary
                cell.updateWithSong(topTrack)
                cell.buyButton.tag = indexPath.row
                cell.buyButton.hidden = false
                if let trackPrice = topTrack["trackPrice"] as? NSNumber {
                    if let trackLink = topTrack["trackViewUrl"] as? String {
                        cell.buyButton.setTitle("$\(trackPrice.description)", forState: .Normal)
                        cell.buyButton.addTarget(self, action: "openTrackLink:", forControlEvents: .TouchUpInside)
                    }
                }
                
                return cell
            }

        } else {
            let cell = tableView.dequeueReusableCellWithIdentifier("RecommendedSearchCell",
                forIndexPath: indexPath) as RecommendedSearchCell
            
            let song = self.recentSongs?[indexPath.row] as NSDictionary
            cell.updateWithSong(song: song)
            
            return cell
        }
    }
    
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if tableView == self.searchDisplayController?.searchResultsTableView {
            let header = self.searchDisplayController?.searchResultsTableView.dequeueReusableHeaderFooterViewWithIdentifier("Header") as ArtistsHeader
            
            if tableView == self.searchDisplayController?.searchResultsTableView {
                if let searchSection = SearchResultsSection(rawValue: section) {
                    switch searchSection {
                    case .SearchSwitch:
                        return nil
                    case .Artists:
                        if self.artists?.count == 0 {
                            return nil
                        }
                        header.infoLabel.text = "Artists"
                    case .Albums:
                        if self.albums?.count == 0 {
                            return nil
                        }
                        header.infoLabel.text = "Albums"
                    default:
                        if self.tracks?.count == 0 {
                            return nil
                        }
                        header.infoLabel.text = "Tracks"
                    }
                }
            }
            
            return header
        }
        
        var header = UIView(frame: CGRectMake(0, 0, self.tableView.frame.size.width, 30))
        header.backgroundColor = UIColor.clearColor()
        return header
    }
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if tableView == self.searchDisplayController?.searchResultsTableView {
            if let searchSection = SearchResultsSection(rawValue: section) {
                switch searchSection {
                case .SearchSwitch:
                    return 0
                case .Artists:
                    if self.artists?.count == 0 {
                        return 0
                    }
                case .Albums:
                    if self.albums?.count == 0 {
                        return 0
                    }
                default:
                    if self.tracks?.count == 0 {
                        return 0
                    }
                }
            }
        }
        
        return 30
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if tableView == self.searchDisplayController?.searchResultsTableView {
            if tableView == self.searchDisplayController?.searchResultsTableView {
                if let searchSection = SearchResultsSection(rawValue: indexPath.section) {
                    switch searchSection {
                    case .Artists:
                        let artist = self.artists?[indexPath.row] as NSDictionary
                        var controller = NowPlayingInfoViewController(artist: artist["artistName"] as String, isForSimiliarArtist: true)
                        self.navigationController?.pushViewController(controller, animated: true)
                    case .Albums: break
                        
                    default: break
                        
                    }
                }
            }
        }
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        self.searchBar.resignFirstResponder()
    }
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        ItunesSearch.sharedInstance().getIdForArtist(searchText, successHandler: { (artists) -> Void in
            if artists.count > 0 {
                if let artistDict = artists.first as? NSDictionary {
                    if let artistID = artistDict.objectForKey("artistId") as? NSNumber {
                        ItunesSearch.sharedInstance().getAlbumsForArtist(artistID, limitOrNil: 1,
                            successHandler: { (artistAlbums) -> Void in
                                self.artists = artistAlbums
                            }, failureHandler: { (error) -> Void in
                                print(error)
                                //self.activityIndicator.stopAnimating()
                        })
                    }
                }
            }
            
            }, failureHandler: { (error) -> Void in
                print(error)
        })
        
        ItunesSearch.sharedInstance().getAlbums(searchText, limit: 5, completion: { (error, results) -> () in
            self.albums = results
        })
        
        ItunesSearch.sharedInstance().getTracks(searchText, limit: 5, completion: { (error, results) -> () in
            self.tracks = results
        })
    }
    
    func searchBarTextDidBeginEditing(searchBar: UISearchBar) {
        //self.searchDisplayController?.setActive(true, animated: true)
    }
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        if self.searchDisplayController?.active == true {
            self.searchDisplayController?.setActive(false, animated: true)
        } else {
            self.dismiss()
        }
    }
    
    func searchDisplayControllerWillBeginSearch(controller: UISearchDisplayController) {
        self.searchDisplayController?.searchBar.showsCancelButton = false
        self.tableView.alpha = 0.0
        self.cancelButton.alpha = 0.0
    }
    
    func searchDisplayControllerWillEndSearch(controller: UISearchDisplayController) {
        self.searchDisplayController?.searchBar.showsCancelButton = true
        self.tableView.alpha = 1.0
        self.cancelButton.alpha = 1.0
    }
    
    func searchDisplayController(controller: UISearchDisplayController, willShowSearchResultsTableView tableView: UITableView) {

    }
    
    func searchDisplayController(controller: UISearchDisplayController, willHideSearchResultsTableView tableView: UITableView) {

    }
    
    func openTrackLink(sender: AnyObject?) {
        if let button = sender as? UIButton {
            print("Button tag: \(button.tag)\n")
            
            let track = self.tracks?[button.tag] as NSDictionary
            if let trackLink = track["trackViewUrl"] as? String {
                LocalyticsSession.shared().tagEvent("Buy track button tapped")
                UIApplication.sharedApplication().openURL(NSURL(string: trackLink)!)
            }
        }
    }
    
    func openAlbumLink(sender: AnyObject?) {
        if let button = sender as? UIButton {
            print("Button tag: \(button.tag)\n")
            
            let album = self.albums?[button.tag] as NSDictionary
            if let albumLink = album["collectionViewUrl"] as? String {
                LocalyticsSession.shared().tagEvent("Buy album button tapped")
                UIApplication.sharedApplication().openURL(NSURL(string: albumLink)!)
            }
        }
    }
    
    func searchSwitchCell(cell: SearchSwitchCell, searchIndexDidChange index: SearchIndex) {
        switch index {
        case .Itunes: break
        default: break
        }
    }
    @IBAction func cancelButtonTapped(sender: AnyObject) {
        self.dismiss()
    }
}
