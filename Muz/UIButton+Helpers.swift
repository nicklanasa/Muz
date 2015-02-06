//
//  UIButton+Helpers.swift
//  Muz
//
//  Created by Nick Lanasa on 2/5/15.
//  Copyright (c) 2015 Nytek Productions. All rights reserved.
//

import Foundation

extension UIButton {
    func applyRoundedStyle() {
        self.layer.cornerRadius = self.frame.size.width/2
        self.layer.masksToBounds = true
        self.layer.borderColor = UIColor.whiteColor().CGColor
        self.layer.borderWidth = 4
    }
}
    