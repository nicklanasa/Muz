//
//  MuzButton.swift
//  Muz
//
//  Created by Nick Lanasa on 12/16/14.
//  Copyright (c) 2014 Nytek Productions. All rights reserved.
//

import Foundation

class MuzButton: UIButton {
    override func draw(_ rect: CGRect) {
        
        self.layer.cornerRadius = 3
        self.layer.masksToBounds = true
        self.layer.borderColor = UIColor.white.cgColor
        self.layer.borderWidth = 1
    }
}
