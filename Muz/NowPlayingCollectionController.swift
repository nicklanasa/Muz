//
//  NowPlayingCollectionController.swift
//  Muz
//
//  Created by Nick Lanasa on 12/18/14.
//  Copyright (c) 2014 Nytek Productions. All rights reserved.
//

import Foundation
import UIKit
import MediaPlayer

protocol NowPlayingCollectionControllerDelegate {
    func nowPlayingCollectionController(_ controller: NowPlayingCollectionController, didSelectItem item: MPMediaItem)
}

class NowPlayingCollectionController: OverlayController,
UITableViewDelegate,
UITableViewDataSource {
    
    fileprivate var currentlyPlayingCollection: MPMediaItemCollection?
    
    var delegate: NowPlayingCollectionControllerDelegate?
    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    
    init(collection: MPMediaItemCollection?) {
        super.init(nibName: "NowPlayingCollectionController", bundle: nil)
        self.currentlyPlayingCollection = collection
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        tableView.register(UINib(nibName: "SongCell", bundle: nil), forCellReuseIdentifier: "Cell")
        tableView.register(UINib(nibName: "ArtistAlbumHeader", bundle: nil), forHeaderFooterViewReuseIdentifier: "Header")
        
        tableView.reloadData()
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "back"),
            style: .plain,
            target: self,
            action: #selector(NowPlayingCollectionController.dismiss as (NowPlayingCollectionController) -> () -> ()))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.overlayScreenName = "Songs"
    }
    
    func dismiss() {
        self.dismiss(animated: true, completion: nil)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return currentlyPlayingCollection?.items.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell",
            for: indexPath) as! SongCell
        
        if let item = currentlyPlayingCollection?.items[indexPath.row] {
            cell.updateWithItem(item)
            cell.accessoryType = .detailDisclosureButton
        }
        
        return cell
    }

    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Get song.
        if let song = currentlyPlayingCollection?.items[indexPath.row]{
            delegate?.nowPlayingCollectionController(self, didSelectItem: song)
            self.dismiss(animated: true, completion: nil)
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
