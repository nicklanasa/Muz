//
//  PlaylistCell.swift
//  Muz
//
//  Created by Nick Lanasa on 12/7/14.
//
//

import Foundation
import UIKit
import MediaPlayer

let PlaylistCellHeight: CGFloat = 65.0

class PlaylistCell: UITableViewCell {
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var infoLabel: UILabel!
    @IBOutlet weak var playlistTypeImageView: UIImageView!
    
    private var playlistQuery = MPMediaQuery.playlistsQuery()
    
    override func awakeFromNib() {
    }
    
    override func prepareForReuse() {
        self.playlistTypeImageView.image = nil
    }
    
    func updateWithPlaylist(playlist: Playlist) {
        self.nameLabel.text = playlist.name
        
        if let playlistType = PlaylistType(rawValue: playlist.playlistType.unsignedLongValue) {
            switch playlistType {
            case .Genius:
                self.playlistTypeImageView.image = UIImage(named: "genius")
            case .Smart:
                self.playlistTypeImageView.image = UIImage(named: "science")
            default:
                self.playlistTypeImageView.image = UIImage(named: "playlistsWhite")
            }
        }
        
        self.updateInfoLabelWithPlaylist(playlist)
    }
    
    private func updateInfoLabelWithPlaylist(playlist: Playlist) {
        
        var songs = playlist.playlistSongs.allObjects
        var playlistDuration = 0.0
        
        if countElements(playlist.persistentID) > 0 {
            let predicate = MPMediaPropertyPredicate(value: playlist.persistentID.toInt(),
                forProperty: MPMediaPlaylistPropertyPersistentID,
                comparisonType: .EqualTo)
            self.playlistQuery.addFilterPredicate(predicate)
            
            songs = playlistQuery.items
            
            for item in self.playlistQuery.items {
                playlistDuration = playlistDuration + item.playbackDuration
            }
        } else {
            for playlistSong in songs as [PlaylistSong] {
                playlistDuration = playlistDuration + playlistSong.song.playbackDuration.doubleValue
            }
        }
        
        self.infoLabel.text = songs.count == 1 ? "\(songs.count) song" : "\(songs.count) songs"
        
        let sec = floor(playlistDuration % 60)
        let min = floor(playlistDuration / 60) % 60
        let hours = floor(playlistDuration / 3600)
        
        if hours + min + sec > 0 {
            self.infoLabel.text = self.infoLabel.text! + " -"
        }
        
        if hours > 0 {
            self.infoLabel.text = self.infoLabel.text! + NSString(format: " %.0fh", hours)
        }
        
        if min > 0 {
            self.infoLabel.text = self.infoLabel.text! + NSString(format: " %.0fm", min)
        }
        
        if sec > 0 {
            self.infoLabel.text = self.infoLabel.text! + NSString(format: " %.0fs", sec)
        }
    }
}