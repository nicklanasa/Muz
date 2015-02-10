//
//  TopAlbumCell.swift
//  Muz
//
//  Created by Nick Lanasa on 2/10/15.
//  Copyright (c) 2015 Nytek Productions. All rights reserved.
//

import Foundation
import UIKit
import MediaPlayer

class TopAlbumCell: UITableViewCell {
    @IBOutlet weak var songLabel: UILabel!
    @IBOutlet weak var infoLabel: UILabel!
    @IBOutlet weak var songImageView: UIImageView!
    @IBOutlet weak var buyButton: UIButton!

    override func awakeFromNib() {
        buyButton.applyBuyStyle()
    }
}