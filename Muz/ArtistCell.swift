//
//  ArtistCell.swift
//  Muz
//
//  Created by Nick Lanasa on 12/7/14.
//
//

import Foundation
import UIKit
import MediaPlayer

class ArtistCell: UITableViewCell {
    @IBOutlet weak var artistLabel: UILabel!
    @IBOutlet weak var infoLabel: UILabel!
    @IBOutlet weak var artistImageView: UIImageView!
    override func awakeFromNib() {
    }
    
    override func prepareForReuse() {
        artistImageView.image = nil
    }
    
    func updateWithItem(song: MPMediaItem) {
        artistLabel.text = song.artist
        infoLabel.text = song.artist
        
        if let artwork = song.artwork {
            artistImageView?.image = song.artwork.imageWithSize(artistImageView.frame.size)
        } else {
            artistImageView?.image = UIImage(named: "noArtwork")
        }
    }
}