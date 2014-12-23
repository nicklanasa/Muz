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
    func artistAlbumHeader(header: ArtistAlbumHeader, moreButtonTapped sender: AnyObject)
}

class ArtistAlbumHeader: UITableViewHeaderFooterView {
    @IBOutlet weak var albumLabel: UILabel!
    @IBOutlet weak var infoLabel: UILabel!
    @IBOutlet weak var yearLabel: UILabel!
    @IBOutlet weak var albumImageView: UIImageView!
    @IBOutlet weak var moreButton: UIButton!
    override func awakeFromNib() {

    }
    
    override func prepareForReuse() {
        
    }
    
    @IBAction func moreButtonTapped(sender: AnyObject) {
        UIAlertView(title: "woot!", message: "", delegate: self, cancelButtonTitle: "ok").show()
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