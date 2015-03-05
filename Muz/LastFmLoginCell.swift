//
//  LastFmUsernameCell.swift
//  Muz
//
//  Created by Nick Lanasa on 3/4/15.
//  Copyright (c) 2015 Nytek Productions. All rights reserved.
//

import Foundation
import UIKit

class LastFmLoginCell: UITableViewCell, UITextFieldDelegate {
    @IBOutlet weak var usernameTextfield: UITextField!
    
    @IBOutlet weak var signupButton: UIButton!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var passwordTextfield: UITextField!
    
    override func awakeFromNib() {
        self.passwordTextfield.delegate = self
        self.usernameTextfield.delegate = self
    }
    
    @IBAction func loginButtonTapped(sender: AnyObject) {
    }
    
    @IBAction func signupButtonTapped(sender: AnyObject) {
    }
}