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
    
    fileprivate var playlistQuery = MPMediaQuery.playlists()
    
    override func awakeFromNib() {
    }
    
    override func prepareForReuse() {
        self.playlistTypeImageView.image = nil
    }
    
    func updateWithPlaylist(_ playlist: Playlist) {
        self.nameLabel.text = playlist.name
        
        if let playlistType = PlaylistType(rawValue: playlist.playlistType.uintValue) {
            switch playlistType {
            case .genius:
                self.playlistTypeImageView.image = UIImage(named: "genius")
            case .smart:
                self.playlistTypeImageView.image = UIImage(named: "science")
            default:
                self.playlistTypeImageView.image = UIImage(named: "playlistsWhite")
            }
        }
        
        self.updateInfoLabelWithPlaylist(playlist)
    }
    
    fileprivate func updateInfoLabelWithPlaylist(_ playlist: Playlist) {
        
        var songs = playlist.playlistSongs.allObjects
        var playlistDuration = 0.0
        
        if let persistentID = playlist.persistentID {
            if persistentID.characters.count > 0 {
                let predicate = MPMediaPropertyPredicate(value: Int(persistentID),
                    forProperty: MPMediaPlaylistPropertyPersistentID,
                    comparisonType: .equalTo)
                self.playlistQuery.addFilterPredicate(predicate)
                
                songs = playlistQuery.items ?? []
                
                if let items = self.playlistQuery.items {
                    for item in items {
                        playlistDuration = playlistDuration + item.playbackDuration
                    }
                }
                
            } else {
                for playlistSong in songs as! [PlaylistSong] {
                    playlistDuration = playlistDuration + playlistSong.song.playbackDuration.doubleValue
                }
            }
        }
        
        
        self.infoLabel.text = songs.count == 1 ? "\(songs.count) song" : "\(songs.count) songs"
        
        let sec = floor(playlistDuration.truncatingRemainder(dividingBy: 60))
        let min = floor(playlistDuration / 60).truncatingRemainder(dividingBy: 60)
        let hours = floor(playlistDuration / 3600)
        
        if hours + min + sec > 0 {
            self.infoLabel.text = self.infoLabel.text! + " -"
        }
        
        if hours > 0 {
            self.infoLabel.text = self.infoLabel.text! + String(format: " %.0fh", hours)
        }
        
        if min > 0 {
            self.infoLabel.text = self.infoLabel.text! + String(format: " %.0fm", min)
        }
        
        if sec > 0 {
            self.infoLabel.text = self.infoLabel.text! + String(format: " %.0fs", sec)
        }
    }
}
