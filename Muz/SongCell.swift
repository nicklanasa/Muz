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

class SongCell: UITableViewCell {
    @IBOutlet weak var songLabel: UILabel!
    @IBOutlet weak var infoLabel: UILabel!
    @IBOutlet weak var songImageView: UIImageView!
    
    override func awakeFromNib() {

    }
    
    func updateWithItem(item: MPMediaItem) {
        self.songLabel.text = item.title
        self.infoLabel.text = item.artist
        self.infoLabel.text = NSString(format: "%@ %@", self.infoLabel.text!, item.albumTitle)
        
        if let artwork = item.artwork {
            self.songImageView?.image = item.artwork.imageWithSize(self.songImageView.frame.size)
        } else {
            self.songImageView?.image = UIImage(named: "noArtwork")
        }

    }
    
    func updateWithSong(song: Song) {
        self.songLabel.text = song.title
        self.infoLabel.text = NSString(format: "%@ %@", self.infoLabel.text!, song.albumTitle)
        self.songImageView.setImageForSong(song: song)
        self.songImageView.applyRoundedStyle()
    }
    
    override func prepareForReuse() {
        songImageView.image = nil
    }
}