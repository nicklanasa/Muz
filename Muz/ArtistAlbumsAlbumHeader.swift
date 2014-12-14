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

class ArtistAlbumsAlbumHeader: UITableViewHeaderFooterView {
    @IBOutlet weak var albumLabel: UILabel!
    @IBOutlet weak var infoLabel: UILabel!
    @IBOutlet weak var yearLabel: UILabel!
    @IBOutlet weak var albumImageView: UIImageView!
    override func awakeFromNib() {

    }
    
    override func prepareForReuse() {
        
    }
    
    func updateWithItem(item: MPMediaItem) {
        
        if let artwork = item.artwork {
            self.albumImageView?.image = artwork.imageWithSize(self.albumImageView.frame.size)
        } else {
            self.albumImageView?.image = UIImage(named: "noArtwork")
        }
        
        if let album = item.albumTitle {
            albumLabel.text = album.isEmpty ? "Unknown Album" : album
        } else {
            albumLabel.text = "Unknown Album"
        }
    }
}