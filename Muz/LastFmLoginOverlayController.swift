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
UITableViewDataSource,
FBLoginViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    var fbLoginView = FBLoginView(frame: CGRectZero)
    
    override init() {
        super.init(nibName: "LastFmLoginOverlayController", bundle: nil)
    }
    
    required override init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.fbLoginView.delegate = self
        self.fbLoginView.readPermissions = ["public_profile", "email", "user_friends"]
        
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
    
    // Facebook Delegate Methods
    
    func loginViewShowingLoggedInUser(loginView : FBLoginView!) {
        println("User Logged In")
    }
    
    func loginViewFetchedUserInfo(loginView : FBLoginView!, user: FBGraphUser) {
        println("User: \(user)")
        println("User ID: \(user.objectID)")
        println("User Name: \(user.name)")
        var userEmail = user.objectForKey("email") as String
        println("User Email: \(userEmail)")
    }
    
    func loginViewShowingLoggedOutUser(loginView : FBLoginView!) {
        println("User Logged Out")
    }
    
    func loginView(loginView : FBLoginView!, handleError:NSError) {
        println("Error: \(handleError.localizedDescription)")
    }
    
    func signup() {
        let alertViewController = UIAlertController(title: "Signup", message: "Please select source to pull email from.", preferredStyle: UIAlertControllerStyle.ActionSheet)
        
        let facebookAction = UIAlertAction(title: "Facebook", style: .Default) { (action) -> Void in
            for obj in self.fbLoginView.subviews {
                if obj.className() == "UIButton" {
                    let button = obj as UIButton
                    button.sendActionsForControlEvents(.TouchUpInside)
                }
            }
        }
        
        let twitterAction = UIAlertAction(title: "Twitter", style: .Default) { (action) -> Void in
            
        }
        
        let usernameAndPassAction = UIAlertAction(title: "Username and password", style: .Default) { (action) -> Void in
            
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel) { (action) -> Void in
            
        }
        
        alertViewController.addAction(facebookAction)
        alertViewController.addAction(twitterAction)
        alertViewController.addAction(usernameAndPassAction)
        alertViewController.addAction(cancelAction)
        
        self.presentViewController(alertViewController, animated: true, completion: nil)
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
            forIndexPath: indexPath) as LastFmLoginCell
        
        return cell
    }
}