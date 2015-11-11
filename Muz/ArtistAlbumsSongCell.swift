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
    
    func configure(song song: Song) {
        self.songLabel.text = song.title
        
        print(song.albumTrackNumber, terminator: "")
        
        let min = floor(song.playbackDuration.doubleValue / 60)
        let sec = floor(song.playbackDuration.doubleValue - (min * 60))
        self.infoLabel.text = String(format: "%.0f:%@%.0f", min, sec < 10 ? "0" : "", sec)
    }
}
