//
//  AlbumsViewController.swift
//  Muz
//
//  Created by Nick Lanasa on 12/7/14.
//
//

import Foundation
import UIKit
import MediaPlayer
import CoreData

class LovedViewController: RootViewController,
UITableViewDelegate,
UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    fileprivate var loved: [AnyObject]?
    fileprivate var lovedQuery: MPMediaQuery!
    fileprivate var sortedResults = NSMutableArray()
    
    init() {
        super.init(nibName: "LovedViewController", bundle: nil)
        
        self.tabBarItem = UITabBarItem(title: nil,
            image: UIImage(named: "loved"),
            selectedImage: UIImage(named: "loved"))
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.register(UINib(nibName: "ArtistCell", bundle: nil), forCellReuseIdentifier: "Cell")
        
        fetchLoved()
                
        self.navigationItem.title = "Loved"
    }
    
    /**
    Fetch songs with rating > 3 and use those items as loved songs.
    */
    fileprivate func fetchLoved() {
        
        self.lovedQuery = MPMediaQuery.songs()
        
        if let items = self.lovedQuery.items {
            var results = NSArray(objects: items)
            
            let sort = NSSortDescriptor(key: "playCount", ascending: false)
            results = results.sortedArray(using: [sort])
            
            for item in results {
                if let song = item as? MPMediaItem {
                    if song.rating > 3 {
                        self.sortedResults.add(song)
                    }
                }
            }
            
            self.tableView.reloadData()
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.sortedResults.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell",
            for: indexPath) as! ArtistCell
        let song = self.sortedResults[indexPath.row] as! MPMediaItem
        
        cell.artistLabel.text = song.title
        cell.infoLabel.text = song.artist
        
        if let artwork = song.artwork {
            cell.artistImageView.image = artwork.image(at: cell.artistImageView.frame.size)
        } else {
            cell.artistImageView.image = UIImage(named: "noArtwork")
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let song = self.sortedResults[indexPath.row] as! MPMediaItem
        //presentNowPlayViewControllerWithItem(song)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.searchBar.resignFirstResponder()
    }
}
