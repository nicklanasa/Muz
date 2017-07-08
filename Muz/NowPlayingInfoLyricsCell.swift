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
        webView.isHidden = true
    }
    
    func updateWithLyrics(_ lyrics: NSString?) {
        activityIndicator.stopAnimating()
        if let lyricsString = lyrics {
            if lyricsString.length > 0 {
                textView.text = lyricsString.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            } else {
                textView.text = "Unable to find lyrics."
            }
        } else {
            textView.text = "Unable to find lyrics."
        }
    }
    
    func webViewDidStartLoad(_ webView: UIWebView) {
        activityIndicator.startAnimating()
    }
    
    func webViewDidFinishLoad(_ webView: UIWebView) {
        if !webView.isLoading {
            activityIndicator.stopAnimating()
            webView.isHidden = false
        }
    }
    
    func updateWithRequest(_ request: URLRequest) {
        webView.loadRequest(request)
    }
    
    override func prepareForReuse() {
        
    }
}
