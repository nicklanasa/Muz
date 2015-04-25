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
    private var buyLinks = [AnyObject]()
    
    private var buyLinksActionSheet: UIActionSheet!
    
    var numberOfValidBuyLinks: Int = 0
    
    /**
    Creates a new LastFmBuyLinksActionSheet with the given array of buy links.
    
    :param: buyLinks The buylinks you want to display.
    
    :returns: void
    */
    init(buyLinks: [AnyObject]) {
        super.init(nibName: "LastFmBuyLinksViewController", bundle: nil)
        self.buyLinks = buyLinks
        configureActionSheet()
    }
    
    init(frame: CGRect) {
        super.init(nibName: "LastFmBuyLinksViewController", bundle: nil)
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /**
    Configures the internal UIActionSheet
    */
    private func configureActionSheet() {
        self.buyLinksActionSheet = UIActionSheet(title: "Select source",
            delegate: self,
            cancelButtonTitle: "Cancel",
            destructiveButtonTitle: nil)
        
        for buyLink in self.buyLinks as! [LastFmBuyLink] {
            if count(buyLink.name) > 0 && buyLink.price.integerValue > 0 {
                let buttonTitle = NSString(format: "%@", buyLink.name, buyLink.price)
                self.buyLinksActionSheet.addButtonWithTitle(buttonTitle as String)
                self.numberOfValidBuyLinks++
            }
        }
    }
    
    func actionSheet(actionSheet: UIActionSheet, clickedButtonAtIndex buttonIndex: Int) {
        
        if buttonIndex == 0 {
            return
        }
        
        if let buyLink = self.buyLinks[buttonIndex - 1] as? LastFmBuyLink {
            LocalyticsSession.shared().tagEvent("Buy album button tapped")
            UIApplication.sharedApplication().openURL(buyLink.url)
        }
    }
    
    /**
    Shows the action view in the given view.
    
    :param: view The view you want the show the action sheet in.
    */
    func showInView(view: UIView) {
        self.buyLinksActionSheet.showInView(view)
    }
}