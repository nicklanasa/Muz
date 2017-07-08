//
//  LastFmBuyLinksViewController.swift
//  Muz
//
//  Created by Nick Lanasa on 12/16/14.
//  Copyright (c) 2014 Nytek Productions. All rights reserved.
//

import Foundation
import UIKit

class LastFmBuyLinksViewController: UIViewController,
UIActionSheetDelegate {
    fileprivate var buyLinks = [AnyObject]()
    
    fileprivate var buyLinksActionSheet: UIActionSheet!
    
    var numberOfValidBuyLinks: Int = 0
    
    /**
    Creates a new LastFmBuyLinksActionSheet with the given array of buy links.
    
    - parameter buyLinks: The buylinks you want to display.
    
    - returns: void
    */
    init(buyLinks: [AnyObject]) {
        super.init(nibName: "LastFmBuyLinksViewController", bundle: nil)
        self.buyLinks = buyLinks
        configureActionSheet()
    }
    
    init(frame: CGRect) {
        super.init(nibName: "LastFmBuyLinksViewController", bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /**
    Configures the internal UIActionSheet
    */
    fileprivate func configureActionSheet() {
        self.buyLinksActionSheet = UIActionSheet(title: "Select source",
            delegate: self,
            cancelButtonTitle: "Cancel",
            destructiveButtonTitle: nil)
        
        for buyLink in self.buyLinks as! [LastFmBuyLink] {
            if buyLink.name.characters.count > 0 && buyLink.price.intValue > 0 {
                let buttonTitle = NSString(format: "%@", buyLink.name, buyLink.price)
                self.buyLinksActionSheet.addButton(withTitle: buttonTitle as String)
                self.numberOfValidBuyLinks += 1
            }
        }
    }
    
    func actionSheet(_ actionSheet: UIActionSheet, clickedButtonAt buttonIndex: Int) {
        
        if buttonIndex == 0 {
            return
        }
        
        if let buyLink = self.buyLinks[buttonIndex - 1] as? LastFmBuyLink {
            UIApplication.shared.openURL(buyLink.url)
        }
    }
    
    /**
    Shows the action view in the given view.
    
    - parameter view: The view you want the show the action sheet in.
    */
    func showInView(_ view: UIView) {
        self.buyLinksActionSheet.show(in: view)
    }
}
