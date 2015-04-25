//
//  LastFmEventInfoController.swift
//  Muz
//
//  Created by Nick Lanasa on 12/12/14.
//  Copyright (c) 2014 Nytek Productions. All rights reserved.
//

import Foundation
import UIKit
import CoreData
import MediaPlayer

class LastFmEventInfoController: RootViewController,
UITableViewDelegate,
UITableViewDataSource,
UIActionSheetDelegate {

    @IBOutlet weak var tableView: UITableView!
    
    var event: LastFmEvent!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.registerNib(UINib(nibName: "LastFmEventInfoDetailsCell", bundle: nil), forCellReuseIdentifier: "LastFmEventInfoDetailsCell")
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Action, target: self, action: "eventActions")
    }
    
    func eventActions() {
        var actionSheet = UIAlertController(title: "Select action", message: nil, preferredStyle: .ActionSheet)
        actionSheet.addAction(UIAlertAction(title: "Open in Safari", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
            self.openInBrowser()
        }))
        actionSheet.addAction(UIAlertAction(title: "View Map", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
            self.showMap()
        }))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Destructive, handler: { (action) -> Void in
            
        }))
        
        if let popoverController = actionSheet.popoverPresentationController {
            popoverController.barButtonItem = self.navigationItem.rightBarButtonItem
        }
        
        self.presentViewController(actionSheet, animated: true, completion: nil)
    }
    
   init() {
        super.init(nibName: "LastFmEventInfoController", bundle: nil)
    }
    
    override func viewWillAppear(animated: Bool) {
        self.screenName = "Event info"
    }
    
    init(event: LastFmEvent) {
        super.init(nibName: "LastFmEventInfoController", bundle: nil)
        self.event = event
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return tableView.frame.height
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCellWithIdentifier("LastFmEventInfoDetailsCell") as! LastFmEventInfoDetailsCell
        cell.updateWithEvent(event)
        return cell
    }
    
    func openInBrowser() {
        UIApplication.sharedApplication().openURL(self.event.url)
    }
    
    func showMap() {
        self.navigationController?.pushViewController(LastFmEventMapController(event: event), animated: true)
    }
}