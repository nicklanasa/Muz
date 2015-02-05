//
//  ArtistAlbumsSongCell.swift
//  Muz
//
//  Created by Nick Lanasa on 12/11/14.
//  Copyright (c) 2014 Nytek Productions. All rights reserved.
//

import Foundation
import UIKit

class ArtistAlbumsSongCell: UITableViewCell {
    @IBOutlet weak var songLabel: UILabel!
    @IBOutlet weak var infoLabel: UILabel!
    override func awakeFromNib() {
    }
    
    override func prepareForReuse() {
    }
    
    func configure(#song: Song) {
        self.songLabel.text = song.title
        self.infoLabel.text = song.artist
    }
}