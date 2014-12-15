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
    
    override func awakeFromNib() {
        artistImageView.layer.cornerRadius = artistImageView.frame.size.height / 2
        artistImageView.layer.masksToBounds = true
        artistImageView.layer.borderColor = UIColor.whiteColor().CGColor
        artistImageView.layer.borderWidth = 1
    }
    
    override func prepareForReuse() {
        
    }
}