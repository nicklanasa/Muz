//
//  LastFmLoginOverlayController.swift
//  Muz
//
//  Created by Nick Lanasa on 3/4/15.
//  Copyright (c) 2015 Nytek Productions. All rights reserved.
//

import Foundation
import UIKit
import LocalAuthentication

class LastFmLoginOverlayController: OverlayController,
UITableViewDelegate,
UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    
    init() {
        super.init(nibName: "LastFmLoginOverlayController", bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel",
            style: .Plain,
            target: self,
            action: "dismiss")
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Signup",
            style: .Plain,
            target: self,
            action: "signup")
        
        tableView.registerNib(UINib(nibName: "LastFmLoginCell", bundle: nil), forCellReuseIdentifier: "Cell")
    }
    
    func signup() {
        UIApplication.sharedApplication().openURL(NSURL(string: "https://m.last.fm/join")!)
    }
    
    func dismiss() {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell",
            forIndexPath: indexPath) as! LastFmLoginCell
        
        return cell
    }
}