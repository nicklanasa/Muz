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
        self.infoLabel.text = song.artist
        self.infoLabel.text = NSString(format: "%@ %@", self.infoLabel.text!, song.albumTitle)

        
        var songQuery = MPMediaQuery.songsQuery()
        songQuery.addFilterPredicate(MPMediaPropertyPredicate(value: song.persistentID,
            forProperty: MPMediaItemPropertyPersistentID,
            comparisonType: .EqualTo))
        
        if let items = songQuery.items {
            if items.count > 0 {
                if let item = items[0] as? MPMediaItem {
                    if let artwork = item.artwork {
                        self.songImageView?.image = artwork.imageWithSize(self.songImageView.frame.size)
                    } else {
                        self.songImageView?.image = UIImage(named: "noArtwork")
                    }
                } else {
                    self.songImageView?.image = UIImage(named: "noArtwork")
                }
            }
        }
    }
    
    override func prepareForReuse() {
        songImageView.image = nil
    }
}