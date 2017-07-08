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
    func crop(_ rect: CGRect) -> UIImage? {
        if let imageRef = self.cgImage?.cropping(to: rect) {
            return UIImage(cgImage: imageRef)
        }
        
        return nil
    }
}
