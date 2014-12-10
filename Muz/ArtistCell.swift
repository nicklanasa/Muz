//
//  ArtistCell.swift
//  Muz
//
//  Created by Nick Lanasa on 12/7/14.
//
//

import Foundation
import UIKit

class ArtistCell: UITableViewCell {
    @IBOutlet weak var artistLabel: UILabel!
    @IBOutlet weak var artistImageView: UIImageView!
    override func awakeFromNib() {
        artistImageView.layer.cornerRadius = 18
        artistImageView.layer.masksToBounds = true
    }
    
    override func prepareForReuse() {
        artistImageView.image = nil
    }
}