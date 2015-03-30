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
    case Artists
    case Albums
    case Tracks
}

protocol SearchOverlayControllerDelegate {
    func searchOverlayController(controller: SearchOverlayController, didTapArtist artist: Artist)
    func searchOverlayController(controller: SearchOverlayController, didTapSong song: Song)
}

class SearchOverlayController: OverlayController,
UITableViewDelegate,
UITableViewDataSource,
UISearchBarDelegate,
UISearchDisplayDelegate,
RecommendedSearchCellDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var recentArtistsLabel: UILabel!
    
    var recentSongs: NSArray?
    
    var delegate: SearchOverlayControllerDelegate?
    
    var artists: NSArray? {
        didSet {
            self.reloadData()
        }
    }
    
    var albums: NSArray? {
        didSet {
            self.reloadData()
        }
    }
    
    var tracks: NSArray? {
        didSet {
            self.reloadData()
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
        var controller = DataManager.manager.datastore.albumsControllerWithSortKey("title",
            ascending: true,
            sectionNameKeyPath: nil)
        return controller
    }()
    
    lazy var songsController: NSFetchedResultsController = {
        var controller = DataManager.manager.datastore.songsControllerWithSortKey("title",
            limit: nil,
            ascending: true,
            sectionNameKeyPath: nil)
        return controller
    }()
    
    func reloadData() {
        self.searchDisplayController?.searchResultsTableView.reloadData()
    }
    
    func resetData() {

        self.artists = nil
        self.albums = nil
        self.tracks = nil
        self.searchDisplayController?.searchResultsTableView.reloadData()
    }
    
    override init() {
        
        ItunesSearch.sharedInstance().affiliateToken = "10lSyo"
        
        super.init(nibName: "SearchOverlayController", bundle: nil)
    }
    
    required override init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewWillAppear(animated: Bool) {
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
        searchDisplayController?.searchResultsTableView.registerNib(UINib(nibName: "SongCell", bundle: nil),
            forCellReuseIdentifier: "SongCell")
        searchDisplayController?.searchResultsTableView.registerNib(UINib(nibName: "TopAlbumCell", bundle: nil),
            forCellReuseIdentifier: "AblumCell")
        searchDisplayController?.searchResultsTableView.registerNib(UINib(nibName: "ArtistsHeader", bundle: nil),
            forHeaderFooterViewReuseIdentifier: "Header")
        
        searchDisplayController?.searchResultsTableView.backgroundColor = UIColor.clearColor()
        searchDisplayController?.searchResultsTableView.separatorStyle = .None
        
        self.recentSongs = DataManager.manager.datastore.distinctArtistSongsWithSortKey("lastPlayedDate",
            limit: 50,
            ascending: false)
        
        self.searchBar.scopeButtonTitles = ["Library", "iTunes Store"]
        self.searchBar.selectedScopeButtonIndex = 0
    }
    
    func dismiss() {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == self.searchDisplayController?.searchResultsTableView {
            if let searchSection = SearchResultsSection(rawValue: section) {
                switch searchSection {
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
            return 3
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

            let songCell = searchDisplayController?.searchResultsTableView.dequeueReusableCellWithIdentifier("SongCell") as SongCell
            
            songCell.buyButton.hidden = true
            songCell.songLabel.text = ""
            songCell.infoLabel.text = ""
            
            cell.buyButton.hidden = true
            cell.songLabel.text = ""
            cell.infoLabel.text = ""
            cell.buyButton.removeTarget(self, action: "openTrackLink", forControlEvents: .TouchUpInside)
            cell.buyButton.removeTarget(self, action: "openAlbumLink", forControlEvents: .TouchUpInside)
            
            let searchSection = SearchResultsSection(rawValue: indexPath.section)!
            switch searchSection {
            case .Artists:
                let artist: AnyObject = self.artists![indexPath.row]
                
                if let libraryArtist = artist as? Artist {
                    songCell.updateWithArtist(libraryArtist)
                    songCell.buyButton.hidden = true
                    return songCell
                } else {
                    cell.updateWithArtist(artist)
                    return cell
                }
            case .Albums:
                let album: AnyObject = self.albums![indexPath.row]
                if let libraryAlbum = album as? Album {
                    songCell.updateWithAlbum(libraryAlbum)
                    songCell.buyButton.hidden = true
                    return songCell
                } else {
                    cell.updateWithAlbum(album, indexPath: indexPath, target: self)
                    return cell
                }
            default:
                let topTrack: AnyObject = self.tracks![indexPath.row]
                
                if let librarySong = topTrack as? Song {
                    songCell.updateWithSong(librarySong)
                    songCell.buyButton.hidden = true
                    return songCell
                } else {
                    cell.updateWithSong(topTrack, indexPath: indexPath, target: self)
                    return cell
                }
            }

        } else {
            let cell = tableView.dequeueReusableCellWithIdentifier("RecommendedSearchCell",
                forIndexPath: indexPath) as RecommendedSearchCell
            
            let song = self.recentSongs?[indexPath.row] as NSDictionary
            cell.updateWithSong(song: song)
            
            cell.delegate = self
            
            return cell
        }
    }
    
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if tableView == self.searchDisplayController?.searchResultsTableView {
            let header = self.searchDisplayController?.searchResultsTableView.dequeueReusableHeaderFooterViewWithIdentifier("Header") as ArtistsHeader
            
            if tableView == self.searchDisplayController?.searchResultsTableView {
                if let searchSection = SearchResultsSection(rawValue: section) {
                    switch searchSection {
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
                        if let artist = self.artists?[indexPath.row] as? NSDictionary {
                            // Open in iTunes Store
                            if let artistViewUrl = artist["artistViewUrl"] as? String {
                                LocalyticsSession.shared().tagEvent("Search iTunes Artist tapped")
                                UIApplication.sharedApplication().openURL(NSURL(string: artistViewUrl)!)
                            }
                        } else {
                            self.dismissViewControllerAnimated(true, completion: { () -> Void in
                                let artist = self.artists?[indexPath.row] as Artist
                                self.delegate?.searchOverlayController(self, didTapArtist: artist)
                            })
                        }
                    case .Albums:
                        if let album = self.albums?[indexPath.row] as? NSDictionary {
                            // Open in iTunes Store
                            if let cell = self.searchDisplayController?.searchResultsTableView.cellForRowAtIndexPath(indexPath) as? TopAlbumCell {
                                self.openAlbumLink(cell.buyButton)
                            }
                        } else {
                            self.dismissViewControllerAnimated(true, completion: { () -> Void in
                                let album = self.albums?[indexPath.row] as Album
                                self.delegate?.searchOverlayController(self, didTapArtist: album.artist)
                            })
                        }
                    default:
                        if let song = self.tracks?[indexPath.row] as? NSDictionary {
                            if let cell = self.searchDisplayController?.searchResultsTableView.cellForRowAtIndexPath(indexPath) as? TopAlbumCell {
                                self.openTrackLink(cell.buyButton)
                            }
                        } else {
                            self.dismissViewControllerAnimated(true, completion: { () -> Void in
                                let song = self.tracks?[indexPath.row] as Song
                                self.delegate?.searchOverlayController(self, didTapSong: song)
                            })
                        }
                    }
                }
            }
        }
        
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        self.searchBar.resignFirstResponder()
    }
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        self.resetData()
        if searchBar.selectedScopeButtonIndex == 0 {
            self.searchLibrary(searchText)
        } else {
            self.searchItunes(searchText)
        }
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
        self.searchBar.scopeBarBackgroundImage = self.backgroundImageView.image?.crop(CGRectMake(0, 0, self.searchBar.frame.size.width, self.searchBar.frame.size.width))
        self.recentArtistsLabel.hidden = true
    }
    
    func searchDisplayControllerWillEndSearch(controller: UISearchDisplayController) {
        self.searchDisplayController?.searchBar.showsCancelButton = true
        self.tableView.alpha = 1.0
        self.cancelButton.alpha = 1.0
        self.recentArtistsLabel.hidden = false
    }
    
    func searchDisplayController(controller: UISearchDisplayController, willShowSearchResultsTableView tableView: UITableView) {

    }
    
    func searchDisplayController(controller: UISearchDisplayController, willHideSearchResultsTableView tableView: UITableView) {

    }
    
    func searchBar(searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        self.resetData()
        if searchBar.selectedScopeButtonIndex == 0 {
            self.searchLibrary(self.searchBar.text)
        } else {
            self.searchItunes(self.searchBar.text)
        }
    }
    
    func openTrackLink(sender: AnyObject?) {
        if let button = sender as? UIButton {
            
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
    
    @IBAction func cancelButtonTapped(sender: AnyObject) {
        self.dismiss()
    }
    
    func recommendedSearchCell(cell: RecommendedSearchCell, didTapRecommendedButton button: AnyObject) {
        if let artistButton = button as? UIButton {
            self.searchDisplayController?.setActive(true, animated: true)
            if let searchText = artistButton.titleForState(.Normal) {
                self.searchDisplayController?.setActive(true, animated: true)
                self.searchDisplayController?.searchBar.text = searchText
                self.searchBar(self.searchDisplayController!.searchBar, textDidChange: searchText)
            }
        }
    }
    
    func searchItunes(searchText: String) {
        ItunesSearch.sharedInstance().getIdForArtist(searchText, successHandler: { (artists) -> Void in
            if artists.count > 0 {
                if let artistDict = artists.first as? NSDictionary {
                    if let artistID = artistDict.objectForKey("artistId") as? NSNumber {
                        ItunesSearch.sharedInstance().getAlbumsForArtist(artistID, limitOrNil: 1,
                            successHandler: { (artistAlbums) -> Void in
                                self.artists = artistAlbums
                            }, failureHandler: { (error) -> Void in
                                print(error)
                        })
                    }
                }
            }
            
            }, failureHandler: { (error) -> Void in
                print(error)
        })
        
        ItunesSearch.sharedInstance().getAlbums(searchText, limit: 10, completion: { (error, results) -> () in
            self.albums = results
        })
        
        ItunesSearch.sharedInstance().getTracks(searchText, limit: 10, completion: { (error, results) -> () in
            self.tracks = results
        })
    }
    
    func searchLibrary(searchText: String) {
        
        var songsPredicate: NSPredicate?
        var artistsPredicate: NSPredicate?
        var albumsPredicate: NSPredicate?
        
        if countElements(searchText) > 0 {
            songsPredicate = NSPredicate(format: "title contains[cd] %@", searchText)
            artistsPredicate = NSPredicate(format: "name contains[cd] %@", searchText)
            albumsPredicate = NSPredicate(format: "title contains[cd] %@", searchText)
            
            self.songsController.fetchRequest.predicate = songsPredicate
            self.songsController.fetchRequest.fetchLimit = 10
            self.artistsController.fetchRequest.predicate = artistsPredicate
            self.artistsController.fetchRequest.fetchLimit = 10
            self.albumsController.fetchRequest.predicate = albumsPredicate
            self.albumsController.fetchRequest.fetchLimit = 10
            
            if self.songsController.performFetch(nil) {
                self.tracks = self.songsController.fetchedObjects
                self.searchDisplayController?.searchResultsTableView.reloadData()
                if self.artistsController.performFetch(nil) {
                    self.artists = self.artistsController.fetchedObjects
                    self.searchDisplayController?.searchResultsTableView.reloadData()
                    if self.albumsController.performFetch(nil) {
                        self.albums = self.albumsController.fetchedObjects
                        self.searchDisplayController?.searchResultsTableView.reloadData()
                    }
                }
            }
        }
    }
}
