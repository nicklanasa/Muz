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
    
    func updateWithItem(_ song: MPMediaItem) {
        artistLabel.text = song.artist
        infoLabel.text = song.artist
        
        if let _ = song.artwork {
            artistImageView?.image = song.artwork?.image(at: artistImageView.frame.size)
        } else {
            artistImageView?.image = UIImage(named: "noArtwork")
        }
    }
    
    func updateWithArtist(_ artist: Artist) {
        artistLabel.text = artist.name
        if artist.albums.count > 0 {
            var songs = 0
            
            for album in artist.albums.allObjects as! [Album] {
                songs += album.songs.count
            }
            
            infoLabel.text = String(format: "%d %@, %d %@", artist.albums.allObjects.count,
                artist.albums.allObjects.count == 1 ? "album" : "albums", songs, songs == 1 ? "song" : "songs")
            infoLabel.isHidden = false
            
        } else {
            infoLabel.isHidden = true
        }
        
        artistImageView.setImageForArtist(artist: artist)
        
        artistImageView.applyRoundedStyle()
    }
}
