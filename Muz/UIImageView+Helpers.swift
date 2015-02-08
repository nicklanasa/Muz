//
//  UIImageView+Helpers.swift
//  Muz
//
//  Created by Nick Lanasa on 2/3/15.
//  Copyright (c) 2015 Nytek Productions. All rights reserved.
//

import Foundation

extension UIImageView {
    
    func applyRoundedStyle() {
        self.layer.cornerRadius = 2
        self.layer.masksToBounds = true
    }
    
    func setImageForArtist(#artist: Artist) {
        DataManager.manager.fetchImageForArtist(artist: artist) { (image, error) -> () in
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                if let artistImage = image {
                    self.image = artistImage
                } else {
                    self.image = UIImage(named: "nowPlayingDefault")
                }
            })
        }
    }
    
    func setImageForAlbum(#album: Album) {
        DataManager.manager.fetchImageForAlbum(album: album) { (image, error) -> () in
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                if let albumImage = image {
                    self.image = albumImage
                } else {
                    self.image = UIImage(named: "nowPlayingDefault")
                }
            })
        }
    }
    
    func setImageForSong(#song: Song) {
        DataManager.manager.fetchImageForSong(song: song) { (image, error) -> () in
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                if let albumImage = image {
                    self.image = albumImage
                } else {
                    self.image = UIImage(named: "nowPlayingDefault")
                }
            })
        }
    }
}