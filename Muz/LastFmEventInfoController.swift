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
        
        tableView.register(UINib(nibName: "LastFmEventInfoDetailsCell", bundle: nil), forCellReuseIdentifier: "LastFmEventInfoDetailsCell")
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(LastFmEventInfoController.eventActions))
    }
    
    func eventActions() {
        let actionSheet = UIAlertController(title: "Select action", message: nil, preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Open in Safari", style: UIAlertActionStyle.default, handler: { (action) -> Void in
            self.openInBrowser()
        }))
        actionSheet.addAction(UIAlertAction(title: "View Map", style: UIAlertActionStyle.default, handler: { (action) -> Void in
            self.showMap()
        }))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.destructive, handler: { (action) -> Void in
            
        }))
        
        if let popoverController = actionSheet.popoverPresentationController {
            popoverController.barButtonItem = self.navigationItem.rightBarButtonItem
        }
        
        self.present(actionSheet, animated: true, completion: nil)
    }
    
   init() {
        super.init(nibName: "LastFmEventInfoController", bundle: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.screenName = "Event info"
    }
    
    init(event: LastFmEvent) {
        super.init(nibName: "LastFmEventInfoController", bundle: nil)
        self.event = event
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return tableView.frame.height
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LastFmEventInfoDetailsCell") as! LastFmEventInfoDetailsCell
        cell.updateWithEvent(event)
        return cell
    }
    
    func openInBrowser() {
        UIApplication.shared.openURL(self.event.url)
    }
    
    func showMap() {
        self.navigationController?.pushViewController(LastFmEventMapController(event: event), animated: true)
    }
}
