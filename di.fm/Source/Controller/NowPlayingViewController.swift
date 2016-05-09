//
//  NowPlayingViewController.swift
//  di.fm
//
//  Created by Charles Magahern on 5/8/16.
//

import Foundation
import UIKit

class NowPlayingViewController : UIViewController
{
    var currentChannel: Channel?
    {
        didSet
        {
            _reloadChannelArtwork()
        }
    }
    
    var server: AudioAddictServer?
    {
        didSet
        {
            _artworkDataSource.server = self.server
        }
    }
    
    private var _artworkImageView: UIImageView = UIImageView()
    private var _artworkDataSource: ChannelArtworkImageDataSource = ChannelArtworkImageDataSource()
    
    private static let _ArtworkSize = CGSize(width: 400.0, height: 400.0)
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?)
    {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        self.title = NSLocalizedString("NOW_PLAYING_TAB", comment: "")
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: UIViewController
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        _artworkImageView.image = UIImage(named: "placeholder-artwork")
        self.view.addSubview(_artworkImageView)
    }
    
    override func viewDidLayoutSubviews()
    {
        super.viewDidLayoutSubviews()
        
        let bounds = self.view.bounds
        let artworkSize = NowPlayingViewController._ArtworkSize
        let artworkFrame = CGRect(
            x: rint(bounds.size.width / 2.0 - artworkSize.width / 2.0),
            y: rint(bounds.size.height / 2.0 - artworkSize.height / 2.0),
            width: artworkSize.width,
            height: artworkSize.height
        )
        _artworkImageView.frame = artworkFrame
    }
    
    // MARK: Internal
    
    internal func _reloadChannelArtwork()
    {
        if (self.currentChannel != nil) {
            let artworkSize = NowPlayingViewController._ArtworkSize
            _artworkDataSource.loadChannelArtworkImage(self.currentChannel!, size: artworkSize, completion: { (image: UIImage?, error: NSError?) -> (Void) in
                dispatch_async(dispatch_get_main_queue()) {
                    if (image != nil) {
                        self._artworkImageView.image = image
                    }
                }
            })
        } else {
            _artworkImageView.image = UIImage(named: "placeholder-artwork")
        }
    }
}
