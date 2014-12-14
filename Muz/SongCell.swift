//
//  ArtistCell.swift
//  Muz
//
//  Created by Nick Lanasa on 12/7/14.
//
//

import Foundation
import UIKit

class SongCell: UITableViewCell {
    @IBOutlet weak var songLabel: UILabel!
    @IBOutlet weak var infoLabel: UILabel!
    @IBOutlet weak var songImageView: UIImageView!
    
    override func awakeFromNib() {

    }
    
    override func prepareForReuse() {
        songImageView.image = nil
    }
}