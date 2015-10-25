//
//  ArtistCell.swift
//  Muz
//
//  Created by Nick Lanasa on 12/7/14.
//
//

import Foundation
import UIKit
import MediaPlayer

class SongCell: SWTableViewCell {
    @IBOutlet weak var songLabel: UILabel!
    @IBOutlet weak var infoLabel: UILabel!
    @IBOutlet weak var songImageView: UIImageView!
    @IBOutlet weak var buyButton: UIButton!
    
    override func awakeFromNib() {
        buyButton.applyBuyStyle()
    }
    
    func updateWithItem(item: MPMediaItem) {
        self.songLabel.text = item.title
        self.infoLabel.text = item.artist
        self.infoLabel.text = String(format: "%@ %@", self.infoLabel.text!, item.albumTitle ?? "")
        
        if let artwork = item.artwork {
            self.songImageView?.image = artwork.imageWithSize(self.songImageView.frame.size)
        } else {
            self.songImageView?.image = UIImage(named: "noArtwork")
        }

    }
    
    func updateWithSong(song: Song) {
        self.songLabel.text = song.title
        self.infoLabel.text = String(format: "%@ %@", song.artist, song.albumTitle)
        self.songImageView.setImageForSong(song: song)
        self.songImageView.applyRoundedStyle()
    }
    
    func updateWithArtist(artist: AnyObject) {
        let libraryArtist = artist as! Artist
        self.songLabel.text = libraryArtist.name
        
        if libraryArtist.albums.count > 0 {
            var songs = 0
            
            for album in libraryArtist.albums.allObjects as! [Album] {
                songs += album.songs.count
            }
            
            infoLabel.text = String(format: "%d %@, %d %@", songs,
                songs == 1 ? "album" : "albums", songs, songs == 1 ? "song" : "songs")
            infoLabel.hidden = false
            
        } else {
            infoLabel.hidden = true
        }
        
        self.songImageView.setImageForArtist(artist: libraryArtist)
        
        self.buyButton.hidden = true
    }
    
    func updateWithAlbum(album: Album) {
        let artistAlbum = album as Album
        self.songLabel.text = artistAlbum.title
        self.infoLabel.text = artistAlbum.songs.count == 1 ? "\(artistAlbum.songs.count) song" : "\(artistAlbum.songs.count) songs"
        self.songImageView.setImageForAlbum(album: artistAlbum)
        
        self.buyButton.hidden = true
    }
    
    func updateWithSong(song: Song, forArtist: Bool) {
        if forArtist {
            self.songLabel.text = song.artist
            self.infoLabel.text = String(format: "%@ %@", song.artist, song.albumTitle)
            self.songImageView.setImageForSong(song: song)
            self.songImageView.applyRoundedStyle()
        } else {
            self.updateWithSong(song)
        }
    }
    
    func updateWithSongData(song: NSDictionary) {
        self.songLabel.text = song.objectForKey("title") as? String
        self.infoLabel.text = song.objectForKey("artist") as? String
        self.songImageView.setImageWithSongData(song: song)
        self.songImageView.applyRoundedStyle()
    }
    
    override func prepareForReuse() {
        songImageView.image = nil
        self.songLabel.text = ""
        self.infoLabel.text = ""
    }
}