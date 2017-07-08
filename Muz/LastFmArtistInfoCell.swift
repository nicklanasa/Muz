//
//  LastFmSongInfoCell.swift
//  Muz
//
//  Created by Nick Lanasa on 12/14/14.
//  Copyright (c) 2014 Nytek Productions. All rights reserved.
//

import Foundation
import UIKit
import MediaPlayer

let LastFmArtistInfoCellHeight: CGFloat = 570.0

protocol LastFmArtistInfoCellDelegate {
    func lastFmArtistInfoCell(_ cell: LastFmArtistInfoCell, didTapTopAlbumsButton albums: [AnyObject]?)
    func lastFmArtistInfoCell(_ cell: LastFmArtistInfoCell, didTapTopTracksButton tracks: [AnyObject]?)
}

class LastFmArtistInfoCell: LastFmCell {
    
    var delegate: LastFmArtistInfoCellDelegate?
    
    @IBOutlet weak var artistLabel: UILabel!
    @IBOutlet weak var artistImageView: UIImageView!
    @IBOutlet weak var listenersLabel: UILabel!
    @IBOutlet weak var playsLabel: UILabel!
    @IBOutlet weak var bioTextView: UITextView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var similiarActivityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var bioActivityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var bioLabel: UILabel!
    @IBOutlet weak var playsDescriptionLabel: UILabel!
    @IBOutlet weak var listenersDescriptionLabel: UILabel!
    @IBOutlet weak var similiarArtistsLabel: UILabel!
    @IBOutlet weak var buyAlbumButton: UIButton!
    @IBOutlet weak var buySongButton: UIButton!
    
    var topAlbums: [AnyObject]?
    var topTracks: [AnyObject]?
    
    var actionSheet: LastFmBuyLinksViewController!
    
    var lastFmArtist: LastFmArtist?
    
    override func awakeFromNib() {
        bringSubview(toFront: collectionView)
        
        artistImageView.layer.cornerRadius = 0
        artistImageView.layer.masksToBounds = true
        
        self.buyAlbumButton.layer.borderColor = UIColor.white.cgColor
        self.buyAlbumButton.layer.borderWidth = 1
        self.buyAlbumButton.layer.cornerRadius = 5
        
        self.buySongButton.layer.borderColor = UIColor.white.cgColor
        self.buySongButton.layer.borderWidth = 1
        self.buySongButton.layer.cornerRadius = 5
    }
    
    func updateWithArtist(_ lastFmArtist: LastFmArtist?) {
        self.lastFmArtist = lastFmArtist
        
        DispatchQueue.main.async(execute: { () -> Void in
            if let artist = lastFmArtist {
                UIView.animate(withDuration: 0.3, animations: { () -> Void in
                    self.artistLabel.alpha = 1.0
                    self.listenersLabel.alpha = 1.0
                    self.playsLabel.alpha = 1.0
                    self.playsLabel.alpha = 1.0
                    self.bioTextView.alpha = 1.0
                    self.bioLabel.alpha = 1.0
                    self.listenersDescriptionLabel.alpha = 1.0
                    self.playsDescriptionLabel.alpha = 1.0
                    self.similiarArtistsLabel.alpha = 1.0
                    self.artistImageView.sd_setImage(with: artist.imageURL)
                    }, completion: { (success) -> Void in
                        if success {
                            let numberFormatter = NumberFormatter()
                            numberFormatter.numberStyle = .decimal
                            
                            let plays = artist.plays ?? 0
                            let listeners = artist.listeners ?? 0
                            
                            self.artistLabel.text = artist.name.characters.count > 0 ? artist.name : "Unknown name."
                            self.listenersLabel.text = listeners == 0 ? "" :  String(format: "%@", numberFormatter.string(from: listeners)!)
                            self.playsLabel.text = plays == 0 ? "" : String(format: "%@", numberFormatter.string(from: plays)!)
                            
                            if artist.bio.characters.count > 0 {
                                self.bioActivityIndicator.stopAnimating()
                            }
                            
                            self.bioTextView.text = artist.bio
                            
                            self.artistImageView.sd_setImage(with: artist.imageURL)
                            
                            self.collectionView.reloadData()
                            
                            self.buyAlbumButton.isHidden = false
                            self.buySongButton.isHidden = false
                        }
                }) 
            }
        })
    }
    
    @IBAction func buySongButtonPressed(_ sender: AnyObject) {
        self.delegate?.lastFmArtistInfoCell(self, didTapTopTracksButton: self.topTracks)
    }
    
    @IBAction func buyAlbumButtonPressed(_ sender: AnyObject) {
        self.delegate?.lastFmArtistInfoCell(self, didTapTopAlbumsButton: self.topAlbums)
    }
    
    fileprivate func showBuyAlbumError() {
        UIAlertView(title: "Error!",
            message: "Unable to find buy links for this album.",
            delegate: self,
            cancelButtonTitle: "Ok").show();
    }
    
    fileprivate func showBuySongError() {
        UIAlertView(title: "Error!",
            message: "Unable to find buy links for this song.",
            delegate: self,
            cancelButtonTitle: "Ok").show();
    }
    
}
