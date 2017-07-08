//
//  PlaylistsViewController.swift
//  Muz
//
//  Created by Nick Lanasa on 12/15/14.
//  Copyright (c) 2014 Nytek Productions. All rights reserved.
//

import Foundation
import UIKit
import MediaPlayer
import CoreData

protocol PlaylistsViewControllerDelegate {
    func playlistsViewController(_ controller: PlaylistsViewController, didSelectPlaylist playlist: Playlist)
}

class PlaylistsViewController: RootViewController,
    UITableViewDelegate,
UITableViewDataSource,
NSFetchedResultsControllerDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    var isForExistingPlaylist = false
    
    // The NSFetchedResultsController used to pull tasks for the selected date.
    var playlistsController: NSFetchedResultsController<NSFetchRequestResult>?
    
    var delegate: PlaylistsViewControllerDelegate?
    
    init() {
        super.init(nibName: "PlaylistsViewController", bundle: nil)
        
        self.tabBarItem = UITabBarItem(title: nil,
            image: UIImage(named: "playlists"),
            selectedImage: UIImage(named: "playlists"))
        
        self.tabBarItem.imageInsets = UIEdgeInsetsMake(6, 0, -6, 0)
    }
    
    init(existingPlaylist: Bool) {
        super.init(nibName: "PlaylistsViewController", bundle: nil)
        self.isForExistingPlaylist = existingPlaylist
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.playlistsController = nil
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.fetchPlaylists()
        super.viewWillAppear(animated)
        
        self.screenName = "Playlists"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.register(UINib(nibName: "PlaylistCell", bundle: nil), forCellReuseIdentifier: "Cell")
        self.tableView.register(UINib(nibName: "SongsHeader", bundle: nil), forHeaderFooterViewReuseIdentifier: "Header")
    
        if !self.isForExistingPlaylist {
            let search = UIBarButtonItem(image: UIImage(named: "search"),
                style: .plain,
                target: self,
                action: #selector(PlaylistsViewController.showSearch))
            
            let addPlaylist = UIBarButtonItem(image: UIImage(named: "add"),
                style: .plain,
                target: self,
                action: #selector(PlaylistsViewController.addPlaylist));
            
            self.navigationItem.rightBarButtonItems = [addPlaylist, search]
        }
    }

    func showSearch() {
        self.presentSearchOverlayController(SearchOverlayController(), blurredController: self)
    }
    
    /**
    Show the create new playlist dialog.
    */
    func addPlaylist() {
        self.presentModalOverlayController(CreatePlaylistOverlay(), blurredController: self)
    }
    
    /**
    Fetch playlists
    */
    fileprivate func fetchPlaylists() {
        if !self.isForExistingPlaylist {
            self.playlistsController = DataManager.manager.datastore.playlistsControllerWithSectionName(nil,
                predicate: nil)
        } else {
            let predicate = NSPredicate(format: "persistentID == ''")
            self.playlistsController = DataManager.manager.datastore.playlistsControllerWithSectionName(nil,
                predicate: predicate)
        }
        
        self.playlistsController?.delegate = self
        
        do {
            try self.playlistsController!.performFetch()
            self.tableView.reloadData()
        } catch {}
    }
    
    // MARK: Sectors NSFetchedResultsControllerDelegate
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>)
    {
        self.tableView.beginUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
        didChange anObject: Any,
        at indexPath: IndexPath?,
        for type: NSFetchedResultsChangeType,
        newIndexPath: IndexPath?)
    {
        let tableView = self.tableView
        var indexPaths:[IndexPath] = [IndexPath]()
        switch type {
            
        case .insert:
            indexPaths.append(newIndexPath!)
            tableView?.insertRows(at: indexPaths, with: .fade)
            
        case .delete:
            indexPaths.append(indexPath!)
            tableView?.deleteRows(at: indexPaths, with: .fade)
            
        case .update:
            indexPaths.append(indexPath!)
            tableView?.reloadRows(at: indexPaths, with: .fade)
            
        case .move:
            indexPaths.append(indexPath!)
            tableView?.deleteRows(at: indexPaths, with: .fade)
            indexPaths.remove(at: 0)
            indexPaths.append(newIndexPath!)
            tableView?.insertRows(at: indexPaths, with: .fade)
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
        didChange sectionInfo: NSFetchedResultsSectionInfo,
        atSectionIndex sectionIndex: Int,
        for type: NSFetchedResultsChangeType)
    {
        switch type {
            
        case .insert:
            self.tableView.insertSections(IndexSet(integer: sectionIndex),
                with: .fade)
            
        case .delete:
            self.tableView.deleteSections(IndexSet(integer: sectionIndex),
                with: .fade)
            
        case .update, .move: print("Move or delete called in didChangeSection")
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>)
    {
        self.tableView.endUpdates()
    }

    
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.playlistsController?.sections?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let numberOfRowsInSection = self.playlistsController?.sections?[section].numberOfObjects {
            return numberOfRowsInSection
        } else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell",
            for: indexPath) as! PlaylistCell
        let playlist = self.playlistsController?.object(at: indexPath) as! Playlist
        cell.updateWithPlaylist(playlist)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if !self.isForExistingPlaylist {
            tableView.deselectRow(at: indexPath, animated: true)
            let playlist = self.playlistsController?.object(at: indexPath) as! Playlist
            DataManager.manager.datastore.updatePlaylist(playlist: playlist, completion: { () -> () in
                DispatchQueue.main.async(execute: { () -> Void in
                    let playlistSongsViewController = PlaylistSongsViewController(playlist: playlist)
                    self.navigationController?.pushViewController(playlistSongsViewController, animated: true)
                })
            })
        } else {
            let playlist = self.playlistsController?.object(at: indexPath) as! Playlist
            self.navigationController?.popViewController(animated: true)
            self.dismissWithPlaylist(playlist)
        }
    }
    
    fileprivate func dismissWithPlaylist(_ playlist: Playlist) {
        self.delegate?.playlistsViewController(self, didSelectPlaylist: playlist)
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        let playlist = self.playlistsController?.object(at: indexPath) as! Playlist
        return (playlist.persistentID!).characters.count == 0
    }
    
    func tableView(_ tableView: UITableView,
        commit editingStyle: UITableViewCellEditingStyle,
        forRowAt indexPath: IndexPath) {
        
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let deleteAction = UITableViewRowAction(style: UITableViewRowActionStyle.default, title: "Delete", handler: { (action, indexPath) -> Void in
            let playlist = self.playlistsController?.object(at: indexPath) as! Playlist
            MediaSession.sharedSession.dataManager.datastore.deletePlaylistWithPlaylist(playlist, completion: { (error) -> () in
                if error == nil {
                    
                } else {
                    UIAlertView(title: "Error!",
                        message: "Unable to delete playlist!",
                        delegate: self,
                        cancelButtonTitle: "Ok").show()
                }
            })
        })

        return [deleteAction]
    }
}
