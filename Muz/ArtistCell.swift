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

let ArtistCellHeight: CGFloat = 65.0

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
    
    func updateWithArtist(artist: Artist) {
        artistLabel.text = artist.name
        infoLabel.text = NSString(format: "%d %@", artist.albums.allObjects.count, artist.albums.allObjects.count == 1 ? "album" : "albums")
        
        artistImageView.setImageForArtist(artist: artist)
        
        artistImageView.applyRoundedStyle()
    }
}