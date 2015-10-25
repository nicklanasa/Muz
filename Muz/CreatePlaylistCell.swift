//
//  CreatePlaylistCell.swift
//  Muz
//
//  Created by Nick Lanasa on 12/19/14.
//  Copyright (c) 2014 Nytek Productions. All rights reserved.
//

import Foundation
import UIKit

let CreatePlaylistCellHeight: CGFloat = 214.0

protocol CreatePlaylistCellDelegate {
    func createPlaylistCell(cell: CreatePlaylistCell, didStartEditing textField: UITextField!)
    func createPlaylistCell(cell: CreatePlaylistCell, shouldReturn textField: UITextField!)
}

class CreatePlaylistCell: UITableViewCell, UITextFieldDelegate {
    
    @IBOutlet weak var amountSegmentedControl: UISegmentedControl!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var smartSwitch: UISwitch!
    @IBOutlet weak var smartLabel: UILabel!
    @IBOutlet weak var amountLabel: UILabel!
    
    var delegate: CreatePlaylistCellDelegate?
    
    override func awakeFromNib() {
        
    }
    
    func textFieldDidBeginEditing(textField: UITextField) {
        
        if textField.text == "Enter playlist name..." {
            textField.textColor = UIColor.whiteColor()
            textField.text = ""
        }
        
        self.delegate?.createPlaylistCell(self, didStartEditing: textField)
    }
    
    @IBAction func smartSwitchDidChange(sender: AnyObject) {
        if let smartSwitch = sender as? UISwitch {
            if smartSwitch.on {
                UIView.animateWithDuration(0.3, animations: { () -> Void in
                    self.amountSegmentedControl.alpha = 1.0
                    self.amountLabel.alpha = 1.0
                })
            } else {
                UIView.animateWithDuration(0.3, animations: { () -> Void in
                    self.amountSegmentedControl.alpha = 0.0
                    self.amountLabel.alpha = 0.0
                })
            }
        }
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        if textField.text?.characters.count == 0 {
            textField.text = "Enter playlist name..."
            textField.textColor = UIColor.lightGrayColor()
        }
    }
    
    func textField(textField: UITextField,
        shouldChangeCharactersInRange range: NSRange,
        replacementString string: String) -> Bool {

        return true
    }

    func textFieldShouldReturn(textField: UITextField) -> Bool {
        self.delegate?.createPlaylistCell(self, shouldReturn: textField)
        return true
    }
}