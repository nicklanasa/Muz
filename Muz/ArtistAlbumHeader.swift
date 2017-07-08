//
//  ArtistAlbumsAlbumHeader.swift
//  Muz
//
//  Created by Nick Lanasa on 12/10/14.
//  Copyright (c) 2014 Nytek Productions. All rights reserved.
//

import Foundation
import UIKit
import MediaPlayer

protocol ArtistAlbumHeaderDelegate {
    func artistAlbumHeader(_ header: ArtistAlbumHeader, moreButtonTapped sender: AnyObject)
}

class ArtistAlbumHeader: UITableViewHeaderFooterView {
    @IBOutlet weak var albumLabel: UILabel!
    @IBOutlet weak var infoLabel: UILabel!
    @IBOutlet weak var yearLabel: UILabel!
    @IBOutlet weak var albumImageView: UIImageView!
    @IBOutlet weak var moreButton: UIButton!
    
    var delegate: ArtistAlbumHeaderDelegate?
    
    var section: Int!
    
    override func awakeFromNib() {
        
    }
    
    override func prepareForReuse() {
        
    }
    
    @IBAction func moreButtonTapped(_ sender: AnyObject) {
        self.delegate?.artistAlbumHeader(self, moreButtonTapped: sender)
    }
    
    func updateWithItem(_ item: MPMediaItem) {
        
        if let artwork = item.artwork {
            self.albumImageView?.image = artwork.image(at: self.albumImageView.frame.size)
        } else {
            self.albumImageView?.image = UIImage(named: "noArtwork")
        }
        
        if let album = item.albumTitle {
            albumLabel.text = album.isEmpty ? "Unknown Album" : album
        } else {
            albumLabel.text = "Unknown Album"
        }
        
        if let date = item.releaseDate {
            let components = (Calendar.current as NSCalendar).components(.year, from: date)
            yearLabel.text = "\(components.year)"
        } else {
            yearLabel.text = ""
        }
        
    }
    
    func updateWithAlbum(album: Album) {
        self.albumImageView.setImageForAlbum(album: album)
        self.albumImageView.applyRoundedStyle()
        
        albumLabel.text = album.title
        infoLabel.text = album.songs.count == 1 ? "\(album.songs.count) song" : "\(album.songs.count) songs"
        if let releaseDate = album.releaseDate {
            let components = (Calendar.current as NSCalendar).components(.year, from: releaseDate as Date)
            yearLabel.text = "\(components.year)"
        } else {
            yearLabel.isHidden = true
        }
    }
}
