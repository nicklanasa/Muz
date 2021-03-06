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
        self.layer.cornerRadius = 0
        self.layer.masksToBounds = true
    }
    
    func setImageForArtist(artist: Artist) {
        DataManager.manager.fetchImageForArtist(artist: artist) { (image, error) -> () in
            DispatchQueue.main.async(execute: { () -> Void in
                if let artistImage = image {
                    self.image = artistImage
                } else {
                    self.image = UIImage(named: "nowPlayingDefault")
                }
            })
        }
    }
    
    func setImageForAlbum(album: Album) {
        DataManager.manager.fetchImageForAlbum(album: album) { (image, error) -> () in
            DispatchQueue.main.async(execute: { () -> Void in
                if let albumImage = image {
                    self.image = albumImage
                } else {
                    self.image = UIImage(named: "nowPlayingDefault")
                }
            })
        }
    }
    
    func setImageForSong(song: Song) {
        DataManager.manager.fetchImageForSong(song: song) { (image, error) -> () in
            DispatchQueue.main.async(execute: { () -> Void in
                if let albumImage = image {
                    self.image = albumImage
                } else {
                    self.image = UIImage(named: "nowPlayingDefault")
                }
            })
        }
    }
    
    func setImageWithSongData(song: NSDictionary) {
        DataManager.manager.fetchImageWithSongData(song: song) { (image, error) -> () in
            DispatchQueue.main.async(execute: { () -> Void in
                if let albumImage = image {
                    self.image = albumImage
                } else {
                    self.image = UIImage(named: "nowPlayingDefault")
                }
            })
        }
    }
}
