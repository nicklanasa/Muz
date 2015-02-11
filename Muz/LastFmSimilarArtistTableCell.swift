//
//  LastFmSimilarArtistTableCell.swift
//  Muz
//
//  Created by Nick Lanasa on 2/7/15.
//  Copyright (c) 2015 Nytek Productions. All rights reserved.
//

import Foundation
import UIKit

class LastFmSimilarArtistTableCell: UITableViewCell {
    
    @IBOutlet weak var noContentLabel: UILabel!
    @IBOutlet weak var similiarActivityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var collectionView: UICollectionView!
    
    override func awakeFromNib() {
        
    }
}