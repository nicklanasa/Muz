//
//  LastFmBuyLinksActionSheet.swift
//  Muz
//
//  Created by Nick Lanasa on 12/16/14.
//  Copyright (c) 2014 Nytek Productions. All rights reserved.
//

import Foundation
import UIKit

class LastFmBuyLinksActionSheet: UIView,
UIActionSheetDelegate {
    var buyLinks = [AnyObject]()
    
    var buyLinksActionSheet: UIActionSheet!
    
    init(buyLinks: [AnyObject]) {
        super.init()
        self.buyLinks = buyLinks
        configureActionSheet()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configureActionSheet() {
        buyLinksActionSheet = UIActionSheet(title: "Select source",
            delegate: self,
            cancelButtonTitle: "Cancel",
            destructiveButtonTitle: nil)
        
        for buyLink in self.buyLinks as [LastFmBuyLink] {
            if countElements(buyLink.name) > 0 && buyLink.price.integerValue > 0 {
                let buttonTitle = NSString(format: "%@ - $%@", buyLink.name, buyLink.price)
                buyLinksActionSheet.addButtonWithTitle(buttonTitle)
            }
        }
    }
    
    func actionSheet(actionSheet: UIActionSheet, clickedButtonAtIndex buttonIndex: Int) {
        
        if buttonIndex == 0 {
            return
        }
        
        if let buyLink = self.buyLinks[buttonIndex - 1] as? LastFmBuyLink {
            UIApplication.sharedApplication().openURL(buyLink.url)
        }
    }
    
    func showInView(view: UIView) {
        buyLinksActionSheet.showInView(view)
    }
}