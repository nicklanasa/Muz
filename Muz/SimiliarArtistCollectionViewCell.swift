//
//  SimiliarArtistCollectionViewCell.swift
//  Muz
//
//  Created by Nick Lanasa on 12/14/14.
//  Copyright (c) 2014 Nytek Productions. All rights reserved.
//

import Foundation
class SimiliarArtistCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var artistImageView: UIImageView!
    @IBOutlet weak var artistLabel: UILabel!
    
    override func awakeFromNib() {
        artistImageView.layer.cornerRadius = 0
        artistImageView.layer.masksToBounds = true
    }
    
    func updateWithArtist(artist: LastFmArtist) {
        artistLabel.text = artist.name
        artistImageView.sd_setImageWithURL(artist.imageURL)
    }
    
    func updateWithSong(song: Song, forArtist: Bool) {
        if forArtist {
            artistLabel.text = song.artist
            artistImageView.setImageForSong(song: song)
        } else {
            artistLabel.text = song.title
            artistImageView.setImageForSong(song: song)
        }
    }
    
    func updateWithSongData(song: NSDictionary, forArtist: Bool) {
        if forArtist {
            artistLabel.text = song.objectForKey("artist") as NSString
        } else {
            artistLabel.text = song.objectForKey("title") as NSString
        }
        
        artistImageView.setImageWithSongData(song: song)
    }
    
    override func prepareForReuse() {

    }
}