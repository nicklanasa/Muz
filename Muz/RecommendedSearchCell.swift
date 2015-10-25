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
    func recommendedSearchCell(cell: RecommendedSearchCell, didTapRecommendedButton button: AnyObject)
}

class RecommendedSearchCell: UITableViewCell {
    
    @IBOutlet weak var recommendedButton: UIButton!
    
    var delegate: RecommendedSearchCellDelegate?
    
    @IBAction func recommendedButtonTapped(sender: AnyObject) {
        self.delegate?.recommendedSearchCell(self, didTapRecommendedButton: sender)
    }
    
    func updateWithSong(song song: NSDictionary) {
        if let artist = song["artist"] as? String {
            self.recommendedButton.setTitle(artist, forState: .Normal)
        }
    }
}
    