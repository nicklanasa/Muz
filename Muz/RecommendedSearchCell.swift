//
//  RecommendedSearchCell.swift
//  Muz
//
//  Created by Nickolas Lanasa on 3/15/15.
//  Copyright (c) 2015 Nytek Productions. All rights reserved.
//

import Foundation
import UIKit

protocol RecommendedSearchCellDelegate {
    func recommendedSearchCell(_ cell: RecommendedSearchCell, didTapRecommendedButton button: AnyObject)
}

class RecommendedSearchCell: UITableViewCell {
    
    @IBOutlet weak var recommendedButton: UIButton!
    
    var delegate: RecommendedSearchCellDelegate?
    
    @IBAction func recommendedButtonTapped(_ sender: AnyObject) {
        self.delegate?.recommendedSearchCell(self, didTapRecommendedButton: sender)
    }
    
    func updateWithSong(song: NSDictionary) {
        if let artist = song["artist"] as? String {
            self.recommendedButton.setTitle(artist, for: UIControlState())
        }
    }
}
    
