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
            style: .plain,
            target: self,
            action: #selector(LastFmLoginOverlayController.dismiss as (LastFmLoginOverlayController) -> () -> ()))
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Signup",
            style: .plain,
            target: self,
            action: #selector(LastFmLoginOverlayController.signup))
        
        tableView.register(UINib(nibName: "LastFmLoginCell", bundle: nil), forCellReuseIdentifier: "Cell")
    }
    
    func signup() {
        UIApplication.shared.openURL(URL(string: "https://m.last.fm/join")!)
    }
    
    func dismiss() {
        self.dismiss(animated: true, completion: nil)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell",
            for: indexPath) as! LastFmLoginCell
        
        return cell
    }
}
