//
//  SearchSwitchCell.swift
//  Muz
//
//  Created by Nickolas Lanasa on 3/15/15.
//  Copyright (c) 2015 Nytek Productions. All rights reserved.
//

import Foundation
import UIKit

enum SearchIndex: Int {
    case library
    case itunes
}

protocol SearchSwitchCellDelegate {
    func searchSwitchCell(_ cell: SearchSwitchCell,
        searchIndexDidChange index: SearchIndex)
}

class SearchSwitchCell: UITableViewCell {
    
    @IBOutlet weak var searchSegmentationControl: UISegmentedControl!
    
    var delegate: SearchSwitchCellDelegate?
    
    override func awakeFromNib() {
        self.bringSubview(toFront: self.searchSegmentationControl)
    }
    
    @IBAction func searchSegmentChanged(_ sender: AnyObject) {
        if let index = SearchIndex(rawValue: searchSegmentationControl.selectedSegmentIndex) {
            self.delegate?.searchSwitchCell(self, searchIndexDidChange: index)
        }
    }
    
}
    
