//
//  UIImage+Helpers.swift
//  Muz
//
//  Created by Nickolas Lanasa on 3/19/15.
//  Copyright (c) 2015 Nytek Productions. All rights reserved.
//

import Foundation
import CoreGraphics

extension UIImage {
    func crop(rect: CGRect) -> UIImage {
        let imageRef = CGImageCreateWithImageInRect(self.CGImage, rect)
        return UIImage(CGImage: imageRef)!
    }
}