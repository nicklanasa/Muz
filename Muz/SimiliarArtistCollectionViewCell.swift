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
        artistImageView.layer.cornerRadius = artistImageView.frame.size.height / 2
        artistImageView.layer.masksToBounds = true
    }
    
    func updateWithArtist(artist: LastFmArtist) {
        artistLabel.text = artist.name
        artistImageView.sd_setImageWithURL(artist.imageURL)
    }
    
    override func prepareForReuse() {

    }
}