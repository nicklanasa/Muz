//
//  ArtistAlbumsAlbumHeader.swift
//  Muz
//
//  Created by Nick Lanasa on 12/10/14.
//  Copyright (c) 2014 Nytek Productions. All rights reserved.
//

import Foundation
import UIKit

class ArtistAlbumsAlbumHeader: UITableViewHeaderFooterView {
    @IBOutlet weak var albumLabel: UILabel!
    @IBOutlet weak var infoLabel: UILabel!
    @IBOutlet weak var yearLabel: UILabel!
    @IBOutlet weak var albumImageView: UIImageView!
    override func awakeFromNib() {

    }
    
    override func prepareForReuse() {
        
    }
    
    func updateWithData(data: NSDictionary) {
        
        if let artworkData = data.objectForKey("artwork") as? NSData {
            if let image = UIImage(data: artworkData) {
                albumImageView.image = image
            } else {
                albumImageView.image = UIImage(named: "noArtwork")
            }
        } else {
            albumImageView.image = UIImage(named: "noArtwork")
        }
        
        if let album = data.objectForKey("albumTitle") as? String {
            albumLabel.text = album.isEmpty ? "Unknown Album" : album
        } else {
            albumLabel.text = "Unknown Album"
        }
    }
}