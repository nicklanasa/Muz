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
    case artists
    case albums
    case tracks
}

protocol SearchOverlayControllerDelegate {
    func searchOverlayController(_ controller: SearchOverlayController, didTapArtist artist: Artist)
    func searchOverlayController(_ controller: SearchOverlayController, didTapSong song: Song)
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
    
    init() {
        
        ItunesSearch.sharedInstance().affiliateToken = "10lSyo"
        
        super.init(nibName: "SearchOverlayController", bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.searchDisplayController?.setActive(true, animated: true)
        self.searchDisplayController?.searchBar.becomeFirstResponder()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(UINib(nibName: "RecommendedSearchCell", bundle: nil),
            forCellReuseIdentifier: "RecommendedSearchCell")
        tableView.register(UINib(nibName: "ArtistsHeader", bundle: nil),
            forHeaderFooterViewReuseIdentifier: "Header")
        
        searchDisplayController?.searchResultsTableView.register(UINib(nibName: "ArtistCell", bundle: nil),
            forCellReuseIdentifier: "ArtistCell")
        searchDisplayController?.searchResultsTableView.register(UINib(nibName: "SongCell", bundle: nil),
            forCellReuseIdentifier: "SongCell")
        searchDisplayController?.searchResultsTableView.register(UINib(nibName: "TopAlbumCell", bundle: nil),
            forCellReuseIdentifier: "AblumCell")
        searchDisplayController?.searchResultsTableView.register(UINib(nibName: "ArtistsHeader", bundle: nil),
            forHeaderFooterViewReuseIdentifier: "Header")
        
        searchDisplayController?.searchResultsTableView.backgroundColor = UIColor.clear
        searchDisplayController?.searchResultsTableView.separatorStyle = .none
        
        self.recentSongs = DataManager.manager.datastore.distinctArtistSongsWithSortKey("lastPlayedDate",
            limit: 50,
            ascending: false)
        
        self.searchBar.scopeButtonTitles = ["Library", "iTunes Store"]
        self.searchBar.selectedScopeButtonIndex = 0
    }
    
    func dismiss() {
        self.dismiss(animated: true, completion: nil)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == self.searchDisplayController?.searchResultsTableView {
            if let searchSection = SearchResultsSection(rawValue: section) {
                switch searchSection {
                case .artists: return self.artists?.count ?? 0
                case .albums: return self.albums?.count ?? 0
                default: return self.tracks?.count ?? 0
                }
            }
            return 0
        }
        
        return self.recentSongs?.count ?? 0
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if tableView == self.searchDisplayController?.searchResultsTableView {
            return 3
        }
        
        return 1
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if tableView == self.searchDisplayController?.searchResultsTableView {
            return 65
        }
        return 40
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if tableView == self.searchDisplayController?.searchResultsTableView {
            
            let cell = searchDisplayController?.searchResultsTableView.dequeueReusableCell(withIdentifier: "AblumCell",
                for: indexPath) as! TopAlbumCell

            let songCell = searchDisplayController?.searchResultsTableView.dequeueReusableCell(withIdentifier: "SongCell") as! SongCell
            
            songCell.buyButton.isHidden = true
            songCell.songLabel.text = ""
            songCell.infoLabel.text = ""
            
            cell.buyButton.isHidden = true
            cell.songLabel.text = ""
            cell.infoLabel.text = ""
            cell.buyButton.removeTarget(self, action: "openTrackLink", for: .touchUpInside)
            cell.buyButton.removeTarget(self, action: "openAlbumLink", for: .touchUpInside)
            
            let searchSection = SearchResultsSection(rawValue: indexPath.section)!
            switch searchSection {
            case .artists:
                let artist: AnyObject = self.artists![indexPath.row] as AnyObject
                
                if let libraryArtist = artist as? Artist {
                    songCell.updateWithArtist(libraryArtist)
                    songCell.buyButton.isHidden = true
                    return songCell
                } else {
                    cell.updateWithArtist(artist)
                    return cell
                }
            case .albums:
                let album: AnyObject = self.albums![indexPath.row] as AnyObject
                if let libraryAlbum = album as? Album {
                    songCell.updateWithAlbum(libraryAlbum)
                    songCell.buyButton.isHidden = true
                    return songCell
                } else {
                    cell.updateWithAlbum(album, indexPath: indexPath, target: self)
                    return cell
                }
            default:
                let topTrack: AnyObject = self.tracks![indexPath.row] as AnyObject
                
                if let librarySong = topTrack as? Song {
                    songCell.updateWithSong(librarySong)
                    songCell.buyButton.isHidden = true
                    return songCell
                } else {
                    cell.updateWithSong(topTrack, indexPath: indexPath, target: self)
                    return cell
                }
            }

        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "RecommendedSearchCell",
                for: indexPath) as! RecommendedSearchCell
            
            let song = self.recentSongs?[indexPath.row] as! NSDictionary
            cell.updateWithSong(song: song)
            
            cell.delegate = self
            
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if tableView == self.searchDisplayController?.searchResultsTableView {
            let header = self.searchDisplayController?.searchResultsTableView.dequeueReusableHeaderFooterView(withIdentifier: "Header") as! ArtistsHeader
            
            if tableView == self.searchDisplayController?.searchResultsTableView {
                if let searchSection = SearchResultsSection(rawValue: section) {
                    switch searchSection {
                    case .artists:
                        if self.artists?.count == 0 {
                            return nil
                        }
                        header.infoLabel.text = "Artists"
                    case .albums:
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
        
        let header = UIView(frame: CGRect(x: 0, y: 0, width: self.tableView.frame.size.width, height: 30))
        header.backgroundColor = UIColor.clear
        return header
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if tableView == self.searchDisplayController?.searchResultsTableView {
            if let searchSection = SearchResultsSection(rawValue: section) {
                switch searchSection {
                case .artists:
                    if self.artists?.count == 0 {
                        return 0
                    }
                case .albums:
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
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView == self.searchDisplayController?.searchResultsTableView {
            if tableView == self.searchDisplayController?.searchResultsTableView {
                if let searchSection = SearchResultsSection(rawValue: indexPath.section) {
                    switch searchSection {
                    case .artists:
                        if let artist = self.artists?[indexPath.row] as? NSDictionary {
                            // Open in iTunes Store
                            if let artistViewUrl = artist["artistViewUrl"] as? String {
                                UIApplication.shared.openURL(URL(string: artistViewUrl)!)
                            }
                        } else {
                            self.dismiss(animated: true, completion: { () -> Void in
                                let artist = self.artists?[indexPath.row] as! Artist
                                self.delegate?.searchOverlayController(self, didTapArtist: artist)
                            })
                        }
                    case .albums:
                        if let album = self.albums?[indexPath.row] as? NSDictionary {
                            // Open in iTunes Store
                            if let cell = self.searchDisplayController?.searchResultsTableView.cellForRow(at: indexPath) as? TopAlbumCell {
                                self.openAlbumLink(cell.buyButton)
                            }
                        } else {
                            self.dismiss(animated: true, completion: { () -> Void in
                                let album = self.albums?[indexPath.row] as! Album
                                self.delegate?.searchOverlayController(self, didTapArtist: album.artist)
                            })
                        }
                    default:
                        if let song = self.tracks?[indexPath.row] as? NSDictionary {
                            if let cell = self.searchDisplayController?.searchResultsTableView.cellForRow(at: indexPath) as? TopAlbumCell {
                                self.openTrackLink(cell.buyButton)
                            }
                        } else {
                            self.dismiss(animated: true, completion: { () -> Void in
                                let song = self.tracks?[indexPath.row] as! Song
                                self.delegate?.searchOverlayController(self, didTapSong: song)
                            })
                        }
                    }
                }
            }
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.searchBar.resignFirstResponder()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.resetData()
        if searchBar.selectedScopeButtonIndex == 0 {
            self.searchLibrary(searchText)
        } else {
            self.searchItunes(searchText)
        }
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        if self.searchDisplayController?.isActive == true {
            self.searchDisplayController?.setActive(false, animated: true)
        } else {
            self.dismiss()
        }
    }
    
    func searchDisplayControllerWillBeginSearch(_ controller: UISearchDisplayController) {
        self.searchDisplayController?.searchBar.showsCancelButton = false
        self.tableView.alpha = 0.0
        self.cancelButton.alpha = 0.0
        self.searchBar.scopeBarBackgroundImage = self.backgroundImageView.image?.crop(CGRect(x: 0, y: 0, width: self.searchBar.frame.size.width, height: self.searchBar.frame.size.width))
        self.recentArtistsLabel.isHidden = true
    }
    
    func searchDisplayControllerWillEndSearch(_ controller: UISearchDisplayController) {
        self.searchDisplayController?.searchBar.showsCancelButton = true
        self.tableView.alpha = 1.0
        self.cancelButton.alpha = 1.0
        self.recentArtistsLabel.isHidden = false
    }
    
    func searchDisplayController(_ controller: UISearchDisplayController, willShowSearchResultsTableView tableView: UITableView) {

    }
    
    func searchDisplayController(_ controller: UISearchDisplayController, willHideSearchResultsTableView tableView: UITableView) {

    }
    
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        self.resetData()
        
        if let searchText = self.searchBar.text {
            if searchBar.selectedScopeButtonIndex == 0 {
                self.searchLibrary(searchText)
            } else {
                self.searchItunes(searchText)
            }
        }
    }
    
    func openTrackLink(_ sender: AnyObject?) {
        if let button = sender as? UIButton {
            
            let track = self.tracks?[button.tag] as! NSDictionary
            if let trackLink = track["trackViewUrl"] as? String {
                UIApplication.shared.openURL(URL(string: trackLink)!)
            }
        }
    }
    
    func openAlbumLink(_ sender: AnyObject?) {
        if let button = sender as? UIButton {
            print("Button tag: \(button.tag)\n", terminator: "")
            
            let album = self.albums?[button.tag] as! NSDictionary
            if let albumLink = album["collectionViewUrl"] as? String {
                UIApplication.shared.openURL(URL(string: albumLink)!)
            }
        }
    }
    
    @IBAction func cancelButtonTapped(_ sender: AnyObject) {
        self.dismiss()
    }
    
    func recommendedSearchCell(_ cell: RecommendedSearchCell, didTapRecommendedButton button: AnyObject) {
        if let artistButton = button as? UIButton {
            self.searchDisplayController?.setActive(true, animated: true)
            if let searchText = artistButton.title(for: UIControlState()) {
                self.searchDisplayController?.setActive(true, animated: true)
                self.searchDisplayController?.searchBar.text = searchText
                self.searchBar(self.searchDisplayController!.searchBar, textDidChange: searchText)
            }
        }
    }
    
    func searchItunes(_ searchText: String) {
        ItunesSearch.sharedInstance().getIdForArtist(searchText, successHandler: { (artists) -> Void in
            if (artists?.count)! > 0 {
                if let artistDict = artists?.first as? NSDictionary {
                    if let artistID = artistDict.object(forKey: "artistId") as? NSNumber {
                        ItunesSearch.sharedInstance().getAlbumsForArtist(artistID, limitOrNil: 1,
                            successHandler: { (artistAlbums) -> Void in
                                self.artists = artistAlbums
                            }, failureHandler: { (error) -> Void in
                                print(error, terminator: "")
                        })
                    }
                }
            }
            
            }, failureHandler: { (error) -> Void in
                print(error, terminator: "")
        })
        
        ItunesSearch.sharedInstance().getAlbums(searchText, limit: 10, completion: { (error, results) -> () in
            self.albums = results
        })
        
        ItunesSearch.sharedInstance().getTracks(searchText, limit: 10, completion: { (error, results) -> () in
            self.tracks = results
        })
    }
    
    func searchLibrary(_ searchText: String) {
        
        var songsPredicate: NSPredicate?
        var artistsPredicate: NSPredicate?
        var albumsPredicate: NSPredicate?
        
        if searchText.characters.count > 0 {
            songsPredicate = NSPredicate(format: "title contains[cd] %@", searchText)
            artistsPredicate = NSPredicate(format: "name contains[cd] %@", searchText)
            albumsPredicate = NSPredicate(format: "title contains[cd] %@", searchText)
            
            self.songsController.fetchRequest.predicate = songsPredicate
            self.songsController.fetchRequest.fetchLimit = 10
            self.artistsController.fetchRequest.predicate = artistsPredicate
            self.artistsController.fetchRequest.fetchLimit = 10
            self.albumsController.fetchRequest.predicate = albumsPredicate
            self.albumsController.fetchRequest.fetchLimit = 10
            
            do {
                try self.songsController.performFetch()
                self.tracks = self.songsController.fetchedObjects
                self.searchDisplayController?.searchResultsTableView.reloadData()
                do {
                    try self.artistsController.performFetch()
                    self.artists = self.artistsController.fetchedObjects
                    self.searchDisplayController?.searchResultsTableView.reloadData()
                    do {
                        try self.albumsController.performFetch()
                        self.albums = self.albumsController.fetchedObjects
                        self.searchDisplayController?.searchResultsTableView.reloadData()
                    } catch _ {
                    }
                } catch _ {
                }
            } catch _ {
            }
        }
    }
}
