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
    case Library
    case Itunes
}

protocol SearchSwitchCellDelegate {
    func searchSwitchCell(cell: SearchSwitchCell,
        searchIndexDidChange index: SearchIndex)
}

class SearchSwitchCell: UITableViewCell {
    
    @IBOutlet weak var searchSegmentationControl: UISegmentedControl!
    
    var delegate: SearchSwitchCellDelegate?
    
    @IBAction func searchSegmentChanged(sender: AnyObject) {
        if let index = SearchIndex(rawValue: searchSegmentationControl.selectedSegmentIndex) {
            self.delegate?.searchSwitchCell(self, searchIndexDidChange: index)
        }
    }
    
}
    