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
    
    private var loved: [AnyObject]?
    private var lovedQuery: MPMediaQuery!
    private var sortedResults = NSMutableArray()
    
    init() {
        super.init(nibName: "LovedViewController", bundle: nil)
        
        self.tabBarItem = UITabBarItem(title: nil,
            image: UIImage(named: "loved"),
            selectedImage: UIImage(named: "loved"))
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.registerNib(UINib(nibName: "ArtistCell", bundle: nil), forCellReuseIdentifier: "Cell")
        
        fetchLoved()
                
        self.navigationItem.title = "Loved"
    }
    
    /**
    Fetch songs with rating > 3 and use those items as loved songs.
    */
    private func fetchLoved() {
        
        self.lovedQuery = MPMediaQuery.songsQuery()
        
        if let items = self.lovedQuery.items {
            var results = NSArray(objects: items)
            
            let sort = NSSortDescriptor(key: "playCount", ascending: false)
            results = results.sortedArrayUsingDescriptors([sort])
            
            for item in results {
                if let song = item as? MPMediaItem {
                    if song.rating > 3 {
                        self.sortedResults.addObject(song)
                    }
                }
            }
            
            self.tableView.reloadData()
        }
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.sortedResults.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell",
            forIndexPath: indexPath) as! ArtistCell
        let song = self.sortedResults[indexPath.row] as! MPMediaItem
        
        cell.artistLabel.text = song.title
        cell.infoLabel.text = song.artist
        
        if let artwork = song.artwork {
            cell.artistImageView.image = artwork.imageWithSize(cell.artistImageView.frame.size)
        } else {
            cell.artistImageView.image = UIImage(named: "noArtwork")
        }
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let song = self.sortedResults[indexPath.row] as! MPMediaItem
        //presentNowPlayViewControllerWithItem(song)
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        self.searchBar.resignFirstResponder()
    }
}
