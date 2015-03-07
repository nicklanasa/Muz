//
//  LastFmUsernameCell.swift
//  Muz
//
//  Created by Nick Lanasa on 3/4/15.
//  Copyright (c) 2015 Nytek Productions. All rights reserved.
//

import Foundation
import UIKit

protocol LastFmLoginCellDelegate {
    func lastFmLoginCellDidTapLoginButton(cell: LastFmLoginCell)
}

class LastFmLoginCell: UITableViewCell, UITextFieldDelegate {
    @IBOutlet weak var usernameTextfield: UITextField!
    
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var passwordTextfield: UITextField!
    @IBOutlet weak var lastfmSwitch: UISwitch!
    
    var delegate: LastFmLoginCellDelegate?
    
    override func awakeFromNib() {
        self.passwordTextfield.delegate = self
        self.usernameTextfield.delegate = self
    }
    
    @IBAction func loginButtonTapped(sender: AnyObject) {
        self.delegate?.lastFmLoginCellDidTapLoginButton(self)
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if textField == self.passwordTextfield {
            self.delegate?.lastFmLoginCellDidTapLoginButton(self)
        }
        
        return true
    }
}