//
//  NSNumber+Helpers.swift
//  Muz
//
//  Created by Nick Lanasa on 2/10/15.
//  Copyright (c) 2015 Nytek Productions. All rights reserved.
//

import Foundation

extension Int {
    func abbreviateNumber() -> String {
        func floatToString(val: Float) -> String {
            var ret: NSString = NSString(format: "%.1f", val)
            
            let c = ret.characterAtIndex(ret.length - 1)
            
            if c == 46 {
                ret = ret.substringToIndex(ret.length - 1)
            }
            
            return ret as String
        }
        
        var abbrevNum = ""
        var num: Float = Float(self)
        
        if num >= 1000 {
            var abbrev = ["K","M","B"]
            
            for var i = abbrev.count-1; i >= 0; i-- {
                let sizeInt = pow(10.0, Double(((i+1)*3)))
                let size = Float(sizeInt)
                
                if size <= num {
                    num = num/size
                    var numStr: String = floatToString(num)
                    if numStr.hasSuffix(".0") {
                        numStr = numStr.substringToIndex(numStr.startIndex.advancedBy(numStr.characters.count-2))
                    }
                    
                    let suffix = abbrev[i]
                    abbrevNum = numStr+suffix
                }
            }
        } else {
            abbrevNum = "\(num)"
            if abbrevNum.hasSuffix(".0") {
                abbrevNum = abbrevNum.substringToIndex(abbrevNum.startIndex.advancedBy(abbrevNum.characters.count-2))
            }
        }
        
        return abbrevNum
    }
}