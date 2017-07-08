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
    
    func updateWithAlbum(_ album: AnyObject,
        indexPath: IndexPath,
        target: AnyObject?) {
        if let artistAlbum = album as? NSDictionary {
            self.infoLabel.text = artistAlbum["artistName"] as? String
            if let albumName = artistAlbum["collectionName"] as? String {
                if let rating = artistAlbum["contentAdvisoryRating"] as? String {
                    self.songLabel.text = albumName + " - " + rating
                } else {
                    self.songLabel.text = albumName
                }
            }
            
            if let image = artistAlbum["artworkUrl100"] as? String {
                self.songImageView.sd_setImage(with: URL(string: image))
            } else {
                self.songImageView.image = UIImage(named: "nowPlayingDefault")
            }
            
            self.buyButton.isHidden = false
            self.buyButton.tag = indexPath.row
            if let albumPrice = album["collectionPrice"] as? NSNumber {
                if let albumLink = album["collectionViewUrl"] as? String {
                    self.buyButton.setTitle("$\(albumPrice.description)", for: UIControlState())
                    self.buyButton.addTarget(target, action: "openAlbumLink:", for: .touchUpInside)
                }
            }
        } else {
            let artistAlbum = album as! Album
            self.songLabel.text = artistAlbum.title
            self.infoLabel.text = artistAlbum.songs.count == 1 ? "\(artistAlbum.songs.count) song" : "\(artistAlbum.songs.count) songs"
            self.songImageView.setImageForAlbum(album: artistAlbum)
            
            self.buyButton.isHidden = true
        }
        
    }
    
    func updateWithArtist(_ artist: AnyObject) {
        if let itunesArtist = artist as? NSDictionary {
            print(artist, terminator: "")
            self.songLabel.text = artist["artistName"] as? String
            self.infoLabel.text = artist["primaryGenreName"] as? String
            if let image = artist["artworkUrl100"] as? String {
                self.songImageView.sd_setImage(with: URL(string: image))
            } else {
                self.songImageView.image = UIImage(named: "nowPlayingDefault")
            }
        } else {
            let libraryArtist = artist as! Artist
            self.songLabel.text = libraryArtist.name
            
            if libraryArtist.albums.count > 0 {
                var songs = 0
                
                for album in libraryArtist.albums.allObjects as! [Album] {
                    songs += album.songs.count
                }
                
                infoLabel.text = String(format: "%d %@, %d %@", songs,
                    songs == 1 ? "album" : "albums", songs, songs == 1 ? "song" : "songs")
                infoLabel.isHidden = false
                
            } else {
                infoLabel.isHidden = true
            }
            
            self.songImageView.setImageForArtist(artist: libraryArtist)
            
            self.buyButton.isHidden = true
        }
        
    }
    
    func updateWithSong(_ song: AnyObject, indexPath: IndexPath, target: AnyObject?) {
        if let itunesSong = song as? NSDictionary {
            self.songLabel.text = song.object(forKey: "trackName") as? String
            self.infoLabel.text = song.object(forKey: "collectionName") as? String
            if let image = song.object(forKey: "artworkUrl100") as? String {
                self.songImageView.sd_setImage(with: URL(string: image))
            } else {
                self.songImageView.image = UIImage(named: "nowPlayingDefault")
            }
            
            self.buyButton.tag = indexPath.row
            self.buyButton.isHidden = false
            
            if let trackPrice = itunesSong["trackPrice"] as? NSNumber {
                if let trackLink = itunesSong["trackViewUrl"] as? String {
                    self.buyButton.setTitle("$\(trackPrice.description)", for: UIControlState())
                    self.buyButton.addTarget(target, action: "openTrackLink:", for: .touchUpInside)
                }
            }

        } else {
            let librarySong = song as! Song
            print(librarySong.artist, terminator: "")
            print(librarySong.albumTitle, terminator: "")
            self.songLabel.text = librarySong.title
            self.infoLabel.text = String(format: "%@ %@", librarySong.artist, librarySong.albumTitle)
            self.songImageView.setImageForSong(song: librarySong)
            
            self.buyButton.isHidden = true
        }
    }
    
    override func prepareForReuse() {
        self.accessoryType = .none
        self.songImageView.image = nil
        self.buyButton.isHidden = true
    }
}
