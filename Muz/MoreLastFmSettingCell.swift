//
//  MoreLastFmSettingCell.swift
//  Muz
//
//  Created by Nick Lanasa on 1/4/15.
//  Copyright (c) 2015 Nytek Productions. All rights reserved.
//

import Foundation
import UIKit

class MoreLastFmSettingCell: UITableViewCell {
    
    @IBOutlet weak var artistInfoLabel: UILabel!
    @IBOutlet weak var poweredByLabel: UILabel!
    @IBOutlet weak var lastFmLogo: UIImageView!
    @IBOutlet weak var artistInfoSwitch: UISwitch!
    
    override func awakeFromNib() {
        self.artistInfoLabel.font = MuzSettingFont
    }
    
    override func prepareForReuse() {
        
    }
}