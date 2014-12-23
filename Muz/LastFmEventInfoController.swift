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
UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    
    var event: LastFmEvent!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.registerNib(UINib(nibName: "LastFmEventInfoDetailsCell", bundle: nil), forCellReuseIdentifier: "LastFmEventInfoDetailsCell")
    }
    
    override init() {
        super.init(nibName: "LastFmEventInfoController", bundle: nil)
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
        var cell = tableView.dequeueReusableCellWithIdentifier("LastFmEventInfoDetailsCell") as LastFmEventInfoDetailsCell
        cell.updateWithEvent(event)
        return cell
    }
}