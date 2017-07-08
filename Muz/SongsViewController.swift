//
//  ArtistsViewController.swift
//  Muz
//
//  Created by Nick Lanasa on 12/7/14.
//
//

import Foundation
import UIKit
import CoreData
import MediaPlayer

class SongsViewController: RootViewController,
UITableViewDelegate,
UITableViewDataSource,
NSFetchedResultsControllerDelegate,
UISearchBarDelegate,
UISearchDisplayDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    lazy var songsController: NSFetchedResultsController = {
        let controller = DataManager.manager.datastore.songsControllerWithSortKey("title",
            limit: nil,
            ascending: true,
            sectionNameKeyPath: "title.stringByGroupingByFirstLetter")
        controller.delegate = self
        return controller
    }()
    
    init() {
        super.init(nibName: "SongsViewController", bundle: nil)
        
        self.tabBarItem = UITabBarItem(title: nil,
            image: UIImage(named: "songs"),
            selectedImage: UIImage(named: "songs"))
        
        self.tabBarItem.imageInsets = UIEdgeInsetsMake(6, 0, -6, 0)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.screenName = "Songs"
        super.viewDidAppear(animated)
        
        fetchSongs()
    }
    
    func fetchSongs() {
        var error: NSError?
        do {
            try self.songsController.performFetch()
            self.tableView.reloadData()
        } catch let error1 as NSError {
            error = error1
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.tableView.setEditing(false, animated: false)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(UINib(nibName: "SongCell", bundle: nil), forCellReuseIdentifier: "Cell")
        tableView.register(UINib(nibName: "SongsHeader", bundle: nil), forHeaderFooterViewReuseIdentifier: "Header")
        
        tableView.backgroundView = UIView()
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "search"),
            style: .plain,
            target: self,
            action: #selector(SongsViewController.showSearch))
    }

    func showSearch() {
        self.presentSearchOverlayController(SearchOverlayController(), blurredController: self)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let numberOfRowsInSection = self.songsController.sections?[section].numberOfObjects {
            return numberOfRowsInSection
        } else {
            return 0
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.songsController.sections?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell",
            for: indexPath) as! SongCell
        
        let song = self.songsController.object(at: indexPath) as! Song
        cell.updateWithSong(song)
        return cell
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if let sectionInfo = self.songsController.sections?[section] {
            let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: "Header") as! SongsHeader
            header.infoLabel.text = sectionInfo.name
            return header
        } else {
            return nil
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 30
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 55
    }

    func sectionIndexTitles(for tableView: UITableView) -> [String]! {
        return self.songsController.sectionIndexTitles
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        self.songsController.fetchRequest.predicate = nil
        self.searchDisplayController?.setActive(false, animated: false)
        
        // Get song.
        let song = self.songsController.object(at: indexPath) as! Song
        
        DataManager.manager.fetchSongsCollection { (collection, error) -> () in
            if collection != nil {
                self.presentNowPlayViewController(song, collection: collection!)
            } else {
                DispatchQueue.main.async(execute: { () -> Void in
                    UIAlertView(title: "Error!",
                        message: "Unable to get collection!",
                        delegate: self,
                        cancelButtonTitle: "Ok").show()
                })
            }
        }

        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let addAction = UITableViewRowAction(style: .normal, title: "Add to playlist") { (action, indexPath) -> Void in
            let song = self.songsController.object(at: indexPath) as! Song
            let createPlaylistOverlay = CreatePlaylistOverlay(songs: [song])
            self.presentModalOverlayController(createPlaylistOverlay, blurredController: self)
        }
        
        return [addAction]
    }
}
