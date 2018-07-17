//
//  NowPlayingViewController.swift
//  di.fm
//
//  Created by Charles Magahern on 5/8/16.
//  Copyright © 2016 zanneth. All rights reserved.
//

import Foundation
import MediaPlayer
import UIKit

protocol NowPlayingViewControllerDelegate : class
{
    func nowPlayingViewControllerDidReturn(_ viewController: NowPlayingViewController)
}

class NowPlayingViewController : UIViewController
{
    weak var delegate: NowPlayingViewControllerDelegate?

    var currentChannel: Channel?
    {
        didSet
        {
            if (oldValue != currentChannel) {
                self.currentTrack = nil // current track is now invalid
                _reloadChannelArtwork()
            }
        }
    }
    
    var currentTrack: Track?
    {
        didSet
        {
            if (oldValue != currentTrack) {
                _reloadMetadataDisplay()
                _reloadSystemNowPlayingInfo()
            }
        }
    }
    
    var server: AudioAddictServer?
    {
        didSet
        {
            _artworkDataSource.server = self.server
        }
    }
    
    var visualizationViewController: VisualizationViewController = VisualizationViewController()
    
    fileprivate var _artworkImageView:   UIImageView = UIImageView()
    fileprivate var _artworkDataSource:  ChannelArtworkImageDataSource = ChannelArtworkImageDataSource()
    fileprivate var _titleLabel:         UILabel = UILabel()
    fileprivate var _artistLabel:        UILabel = UILabel()
    fileprivate var _ff:                 UIButton = UIButton()
    
    fileprivate static let _ArtworkSize = CGSize(width: 500.0, height: 500.0)
    fileprivate static let _ArtworkTitlePadding = CGFloat(60.0)
    fileprivate static let _TitleArtistLeading = CGFloat(5.0)
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?)
    {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        self.title = NSLocalizedString("NOW_PLAYING_TAB", comment: "")
        self.visualizationViewController.setLevelMetersVisible(false, animated: false)
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: UIViewController
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        let visualizationView = self.visualizationViewController.view
        self.addChildViewController(self.visualizationViewController)
        self.view.addSubview(visualizationView!)
        
        self.view.addSubview(_artworkImageView)
        _reloadChannelArtwork()
        
        let theme = Theme.defaultTheme()
        _titleLabel.font = theme.titleFont
        _titleLabel.textColor = theme.foregroundColor
        _titleLabel.textAlignment = .center
        self.view.addSubview(_titleLabel)
        
        _artistLabel.font = theme.foregroundFont
        _artistLabel.textColor = theme.tertiaryColor.lighterColor()
        _artistLabel.textAlignment = .center
        self.view.addSubview(_artistLabel)
        
        _ff.addTarget(self, action: #selector(buttonAction), for: .primaryActionTriggered)
        self.view.addSubview(_ff)
    }
    
    @objc func buttonAction(sender: UIButton!)
    {
        self.delegate?.nowPlayingViewControllerDidReturn(self)
    }
    
    override func viewDidLayoutSubviews()
    {
        super.viewDidLayoutSubviews()
        
        let bounds = self.view.bounds
        let artworkSize = NowPlayingViewController._ArtworkSize
        let titleSize = _titleLabel.sizeThatFits(bounds.size)
        let artistSize = _artistLabel.sizeThatFits(bounds.size)
        let artworkTitlePadding = NowPlayingViewController._ArtworkTitlePadding
        let titleArtistLeading = NowPlayingViewController._TitleArtistLeading
        let totalViewsHeight = (
            artworkSize.height +
            artworkTitlePadding +
            titleSize.height +
            titleArtistLeading +
            artistSize.height
        )
        
        let visualizationFrame = bounds
        self.visualizationViewController.view.frame = visualizationFrame
        
        let artworkFrame = CGRect(
            x: rint(bounds.size.width / 2.0 - artworkSize.width / 2.0),
            y: rint(bounds.size.height / 2.0 - totalViewsHeight / 2.0),
            width: artworkSize.width,
            height: artworkSize.height
        )
        _artworkImageView.frame = artworkFrame
        self.visualizationViewController.levelMetersCenter = CGPoint(x: artworkFrame.midX, y: artworkFrame.midY)
        
        let labelsWidth = artworkFrame.size.width * 2.0
        let titleFrame = CGRect(
            x: rint(bounds.size.width / 2.0 - labelsWidth / 2.0),
            y: artworkFrame.maxY + artworkTitlePadding,
            width: labelsWidth,
            height: titleSize.height
        )
        _titleLabel.frame = titleFrame
        
        let artistFrame = CGRect(
            x: rint(bounds.size.width / 2.0 - labelsWidth / 2.0),
            y: titleFrame.maxY + titleArtistLeading,
            width: labelsWidth,
            height: artistSize.height
        )
        _artistLabel.frame = artistFrame
        
        let ffFrame = CGRect(x: 0, y: 0, width: 1, height: 1)
        _ff.frame = ffFrame
    }
    
    // MARK: Internal
    
    internal func _reloadChannelArtwork()
    {
        _artworkImageView.image = UIImage(named: "placeholder-artwork")
        _reloadSystemNowPlayingInfo()
        
        if let currentChannel = self.currentChannel {
            let artworkSize = NowPlayingViewController._ArtworkSize
            _artworkDataSource.loadChannelArtworkImage(currentChannel, size: artworkSize, completion: { (image: UIImage?, error: Error?) -> (Void) in
                DispatchQueue.main.async {
                    if (image != nil) {
                        self._artworkImageView.image = image
                        self._reloadSystemNowPlayingInfo()
                    }
                }
            })
        }
    }
    
    internal func _reloadMetadataDisplay()
    {
        DispatchQueue.main.async {
            let metadataWasEmpty = (self._titleLabel.text?.isEmpty ?? true && self._artistLabel.text?.isEmpty ?? true)
            self._titleLabel.text = self.currentTrack?.title
            self._artistLabel.text = self.currentTrack?.artist
            self.view.setNeedsLayout()
            
            if (metadataWasEmpty) {
                self._titleLabel.alpha = 0.0
                self._artistLabel.alpha = 0.0
            }
            
            UIView.animate(withDuration: 0.5, animations: {
                self.view.layoutIfNeeded()
                self._titleLabel.alpha = 1.0
                self._artistLabel.alpha = 1.0
            }) 
            
            let metadataNowEmpty = (self._titleLabel.text?.isEmpty ?? true && self._artistLabel.text?.isEmpty ?? true)
            if (!metadataNowEmpty) {
                let delay = DispatchTime.now() + Double(Int64(1 * NSEC_PER_SEC)) / Double(NSEC_PER_SEC)
                DispatchQueue.main.asyncAfter(deadline: delay, execute: {
                    self.visualizationViewController.setLevelMetersVisible(true, animated: true)
                })
            } else {
                self.visualizationViewController.setLevelMetersVisible(false, animated: false)
            }
        }
    }
    
    internal func _reloadSystemNowPlayingInfo()
    {
        let npInfoCenter = MPNowPlayingInfoCenter.default()
        var npInfo: [String : AnyObject]? = nil
        if let currentTrack = self.currentTrack {
            npInfo = [
                MPMediaItemPropertyTitle : currentTrack.title as AnyObject,
                MPMediaItemPropertyArtist : currentTrack.artist as AnyObject,
                MPMediaItemPropertyAlbumTitle : currentTrack.album as AnyObject
            ]
            
            /* this was fixed in iOS 10.0 I think...
            if let artwork = _artworkImageView.image {
                npInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork()
            }
            */
        }
        npInfoCenter.nowPlayingInfo = npInfo
    }
}
