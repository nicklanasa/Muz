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

class ArtistsViewController: RootViewController,
UITableViewDelegate,
UITableViewDataSource,
NSFetchedResultsControllerDelegate,
UISearchBarDelegate,
UISearchDisplayDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    var artistsController: NSFetchedResultsController<NSFetchRequestResult>!
    
    init() {
        super.init(nibName: "ArtistsViewController", bundle: nil)
        
        self.tabBarItem = UITabBarItem(title: nil,
            image: UIImage(named: "artists"),
            selectedImage: UIImage(named: "artists"))
        
        self.tabBarItem.imageInsets = UIEdgeInsetsMake(6, 0, -6, 0)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let predicate = NSPredicate(format: "albums.@count != 0")
        self.artistsController = DataManager.manager.datastore.artistsController(predicate, sortKey: "name",
            ascending: true,
            sectionNameKeyPath: "name.stringByGroupingByFirstLetter")
        self.artistsController.delegate = self
        
        fetchArtists()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.tableView.setEditing(false, animated: false)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(UINib(nibName: "ArtistCell", bundle: nil), forCellReuseIdentifier: "Cell")
        tableView.register(UINib(nibName: "ArtistsHeader", bundle: nil), forHeaderFooterViewReuseIdentifier: "Header")
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "search"),
            style: .plain,
            target: self,
            action: #selector(ArtistsViewController.showSearch))
        
        self.screenName = "Artists"
    }
    
    func showSearch() {
        self.presentSearchOverlayController(SearchOverlayController(), blurredController: self)
    }
    
    func fetchArtists() {
        do {
            try self.artistsController.performFetch()
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
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let numberOfRowsInSection = self.artistsController.sections?[section].numberOfObjects {
            return numberOfRowsInSection
        } else {
            return 0
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.artistsController.sections?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell",
            for: indexPath) as! ArtistCell
        
        let artist = self.artistsController.object(at: indexPath) as! Artist
        cell.updateWithArtist(artist)
    
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 30
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if let sectionInfo = self.artistsController.sections?[section] {
            let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: "Header") as! ArtistsHeader
            header.infoLabel.text = sectionInfo.name
            return header
        } else {
            return nil
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.artistsController.fetchRequest.predicate = nil
        self.searchDisplayController?.setActive(false, animated: false)
        tableView.deselectRow(at: indexPath, animated: true)
        let artist = self.artistsController.object(at: indexPath) as! Artist
        let artistAlbumsViewController = ArtistAlbumsViewController(artist: artist)
        navigationController?.pushViewController(artistAlbumsViewController, animated: true)
    }
    
    func sectionIndexTitles(for tableView: UITableView) -> [String]! {
        return self.artistsController.sectionIndexTitles
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return ArtistCellHeight
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let addAction = UITableViewRowAction(style: .normal, title: "Add to playlist") { (action, indexPath) -> Void in
            let artist = self.artistsController.object(at: indexPath) as! Artist
            let createPlaylistOverlay = CreatePlaylistOverlay(artist: artist.name)
            self.presentModalOverlayController(createPlaylistOverlay, blurredController: self)
        }
        
        return [addAction]
    }
}
