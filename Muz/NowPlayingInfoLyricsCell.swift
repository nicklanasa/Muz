//
//  NowPlayingInfoLyricsCell.swift
//  Muz
//
//  Created by Nick Lanasa on 12/12/14.
//  Copyright (c) 2014 Nytek Productions. All rights reserved.
//

import Foundation
import UIKit
import MediaPlayer

class NowPlayingInfoLyricsCell: UITableViewCell,
UIWebViewDelegate {
    
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var webView: UIWebView!
    
    override func awakeFromNib() {
        webView.delegate = self
        webView.hidden = true
    }
    
    func updateWithLyrics(lyrics: NSString?) {
        activityIndicator.stopAnimating()
        if let lyricsString = lyrics {
            if lyricsString.length > 0 {
                textView.text = lyricsString.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
            } else {
                textView.text = "Unable to find lyrics."
            }
        } else {
            textView.text = "Unable to find lyrics."
        }
    }
    
    func webViewDidStartLoad(webView: UIWebView) {
        activityIndicator.startAnimating()
    }
    
    func webViewDidFinishLoad(webView: UIWebView) {
        if !webView.loading {
            activityIndicator.stopAnimating()
            webView.hidden = false
        }
    }
    
    func updateWithRequest(request: NSURLRequest) {
        webView.loadRequest(request)
    }
    
    override func prepareForReuse() {
        
    }
}