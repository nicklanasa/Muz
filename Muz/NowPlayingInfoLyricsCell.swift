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

class NowPlayingInfoLyricsCell: UITableViewCell {
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    override func awakeFromNib() {
        
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
    
    override func prepareForReuse() {
        
    }
}