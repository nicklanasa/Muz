//
//  TopAlbumCell.swift
//  Muz
//
//  Created by Nick Lanasa on 2/10/15.
//  Copyright (c) 2015 Nytek Productions. All rights reserved.
//

import Foundation
import UIKit
import MediaPlayer

class TopAlbumCell: UITableViewCell {
    @IBOutlet weak var songLabel: UILabel!
    @IBOutlet weak var infoLabel: UILabel!
    @IBOutlet weak var songImageView: UIImageView!
    @IBOutlet weak var buyButton: UIButton!

    override func awakeFromNib() {
        buyButton.applyBuyStyle()
    }
    
    func updateWithAlbum(album: NSDictionary) {
        self.infoLabel.text = album["artistName"] as? String
        if let albumName = album["collectionName"] as? String {
            if let rating = album["contentAdvisoryRating"] as? String {
                self.songLabel.text = albumName + " - " + rating
            } else {
                self.songLabel.text = albumName
            }
        }
        
        if let image = album["artworkUrl100"] as? String {
            self.songImageView.sd_setImageWithURL(NSURL(string: image))
        } else {
            self.songImageView.image = UIImage(named: "nowPlayingDefault")
        }
    }
    
    func updateWithArtist(artist: NSDictionary) {
        print(artist)
        self.songLabel.text = artist["artistName"] as? String
        self.infoLabel.text = artist["primaryGenreName"] as? String
        if let image = artist["artworkUrl100"] as? String {
            self.songImageView.sd_setImageWithURL(NSURL(string: image))
        } else {
            self.songImageView.image = UIImage(named: "nowPlayingDefault")
        }
    }
    
    func updateWithSong(song: NSDictionary) {
        self.songLabel.text = song.objectForKey("trackName") as? String
        self.infoLabel.text = song.objectForKey("collectionName") as? String
        if let image = song.objectForKey("artworkUrl100") as? String {
            self.songImageView.sd_setImageWithURL(NSURL(string: image))
        } else {
            self.songImageView.image = UIImage(named: "nowPlayingDefault")
        }
    }
}