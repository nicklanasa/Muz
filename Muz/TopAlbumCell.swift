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
    @IBOutlet weak var songLabelTrailingSpaceConstraint: NSLayoutConstraint!
    @IBOutlet weak var infoLabelTrailingSpaceConstraint: NSLayoutConstraint!
    @IBOutlet weak var progressView: FFCircularProgressView!
    
    override func awakeFromNib() {
        buyButton.applyBuyStyle()
        progressView.progress = 0.0
        progressView.tintColor = MuzBlueColor
        progressView.tickColor = MuzBlueColor
    }
    
    func updateWithAlbum(album: AnyObject,
        indexPath: NSIndexPath,
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
                self.songImageView.sd_setImageWithURL(NSURL(string: image))
            } else {
                self.songImageView.image = UIImage(named: "nowPlayingDefault")
            }
            
            self.buyButton.hidden = false
            self.buyButton.tag = indexPath.row
            if let albumPrice = album["collectionPrice"] as? NSNumber {
                if let albumLink = album["collectionViewUrl"] as? String {
                    self.buyButton.setTitle("$\(albumPrice.description)", forState: .Normal)
                    self.buyButton.addTarget(target, action: "openAlbumLink:", forControlEvents: .TouchUpInside)
                }
            }
        } else {
            let artistAlbum = album as Album
            self.songLabel.text = artistAlbum.title
            self.infoLabel.text = artistAlbum.songs.count == 1 ? "\(artistAlbum.songs.count) song" : "\(artistAlbum.songs.count) songs"
            self.songImageView.setImageForAlbum(album: artistAlbum)
            
            self.buyButton.hidden = true
            self.accessoryType = .DisclosureIndicator
        }
        
    }
    
    func updateWithArtist(artist: AnyObject) {
        if let itunesArtist = artist as? NSDictionary {
            print(artist)
            self.songLabel.text = artist["artistName"] as? String
            self.infoLabel.text = artist["primaryGenreName"] as? String
            if let image = artist["artworkUrl100"] as? String {
                self.songImageView.sd_setImageWithURL(NSURL(string: image))
            } else {
                self.songImageView.image = UIImage(named: "nowPlayingDefault")
            }
        } else {
            let libraryArtist = artist as Artist
            self.songLabel.text = libraryArtist.name
            
            if libraryArtist.albums.count > 0 {
                var songs = 0
                
                for album in libraryArtist.albums.allObjects as [Album] {
                    songs += album.songs.count
                }
                
                infoLabel.text = NSString(format: "%d %@, %d %@", songs,
                    songs == 1 ? "album" : "albums", songs, songs == 1 ? "song" : "songs")
                infoLabel.hidden = false
                
            } else {
                infoLabel.hidden = true
            }
            
            self.songImageView.setImageForArtist(artist: libraryArtist)
            
            self.buyButton.hidden = true
            self.accessoryType = .DisclosureIndicator
        }
        
    }
    
    func updateWithSong(song: AnyObject, indexPath: NSIndexPath, target: AnyObject?) {
        if let itunesSong = song as? NSDictionary {
            self.songLabel.text = song.objectForKey("trackName") as? String
            self.infoLabel.text = song.objectForKey("collectionName") as? String
            if let image = song.objectForKey("artworkUrl100") as? String {
                self.songImageView.sd_setImageWithURL(NSURL(string: image))
            } else {
                self.songImageView.image = UIImage(named: "nowPlayingDefault")
            }
            
            self.buyButton.tag = indexPath.row
            self.buyButton.hidden = false
            
            if let trackPrice = itunesSong["trackPrice"] as? NSNumber {
                if let trackLink = itunesSong["trackViewUrl"] as? String {
                    self.buyButton.setTitle("$\(trackPrice.description)", forState: .Normal)
                    self.buyButton.addTarget(target, action: "openTrackLink:", forControlEvents: .TouchUpInside)
                }
            }

        } else {
            let librarySong = song as Song
            print(librarySong.artist)
            print(librarySong.albumTitle)
            self.songLabel.text = librarySong.title
            self.infoLabel.text = NSString(format: "%@ %@", librarySong.artist, librarySong.albumTitle)
            self.songImageView.setImageForSong(song: librarySong)
            
            self.buyButton.hidden = true
            
            self.accessoryType = .DisclosureIndicator
        }
    }
    
    override func prepareForReuse() {
        self.accessoryType = .None
        self.songImageView.image = nil
        self.buyButton.hidden = true
    }
}