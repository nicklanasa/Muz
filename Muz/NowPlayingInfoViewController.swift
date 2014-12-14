//
//  NowPlayingInfoViewController.swift
//  Muz
//
//  Created by Nick Lanasa on 12/12/14.
//  Copyright (c) 2014 Nytek Productions. All rights reserved.
//

import Foundation
import UIKit
import CoreData
import MediaPlayer

class NowPlayingInfoViewController: RootViewController, UITableViewDelegate, UITableViewDataSource, LyricsRequestDelegate {

    @IBOutlet weak var tableView: UITableView!
    
    var lyricsRequest: LyricsRequest?
    
    var item: MPMediaItem?
    var lyrics = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.registerNib(UINib(nibName: "NowPlayingInfoLyricsCell", bundle: nil), forCellReuseIdentifier: "Cell")
        
        tableView.autoresizingMask = .FlexibleWidth | .FlexibleHeight
        view.autoresizingMask = .FlexibleWidth | .FlexibleHeight
    }
    
    override init() {
        super.init(nibName: "NowPlayingInfoViewController", bundle: nil)
    }
    
    func updateWithItem(item: MPMediaItem) {
        self.item = item
        
        let stringURL = NSString(format: "http://search.azlyrics.com/search.php?q=%@ %@", item.artist, item.title).stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)
        let lyricsURL = NSURL(string: stringURL!)!
        var request = LyricsRequest(url: lyricsURL, item: item)
        request.delegate = self
        request.sendURLRequest()
    }
    
    func lyricsRequestDidComplete(request: LyricsRequest, didCompleteWithLyrics lyrics: String) {
        self.lyrics = lyrics
        tableView.reloadData()
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
        var cell = tableView.dequeueReusableCellWithIdentifier("Cell") as NowPlayingInfoLyricsCell
        cell.updateWithLyrics(self.lyrics)
        return cell
    }
}