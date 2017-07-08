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
    func createPlaylistCell(_ cell: CreatePlaylistCell, didStartEditing textField: UITextField!)
    func createPlaylistCell(_ cell: CreatePlaylistCell, shouldReturn textField: UITextField!)
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
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        
        if textField.text == "Enter playlist name..." {
            textField.textColor = UIColor.white
            textField.text = ""
        }
        
        self.delegate?.createPlaylistCell(self, didStartEditing: textField)
    }
    
    @IBAction func smartSwitchDidChange(_ sender: AnyObject) {
        if let smartSwitch = sender as? UISwitch {
            if smartSwitch.isOn {
                UIView.animate(withDuration: 0.3, animations: { () -> Void in
                    self.amountSegmentedControl.alpha = 1.0
                    self.amountLabel.alpha = 1.0
                })
            } else {
                UIView.animate(withDuration: 0.3, animations: { () -> Void in
                    self.amountSegmentedControl.alpha = 0.0
                    self.amountLabel.alpha = 0.0
                })
            }
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField.text?.characters.count == 0 {
            textField.text = "Enter playlist name..."
            textField.textColor = UIColor.lightGray
        }
    }
    
    func textField(_ textField: UITextField,
        shouldChangeCharactersIn range: NSRange,
        replacementString string: String) -> Bool {

        return true
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.delegate?.createPlaylistCell(self, shouldReturn: textField)
        return true
    }
}
