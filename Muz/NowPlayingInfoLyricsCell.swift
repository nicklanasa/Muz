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
    
    override func awakeFromNib() {
        
    }
    
    func updateWithLyrics(lyrics: NSString) {
        textView.text = lyrics
    }
    
    override func prepareForReuse() {
        
    }
}