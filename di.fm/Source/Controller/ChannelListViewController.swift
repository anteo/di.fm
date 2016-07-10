//
//  ChannelListViewController.swift
//  di.fm
//
//  Created by Charles Magahern on 5/8/16.
//

import Foundation
import UIKit

protocol ChannelListViewControllerDelegate: class
{
    func channelListDidSelectChannel(controller: ChannelListViewController, channel: Channel)
}

class ChannelListViewController : UIViewController, UICollectionViewDelegate, UICollectionViewDataSource
{
    static private let CollectionViewReuseIdentifier = "CollectionViewReuseIdentifier"
    static private let LayoutTemplate = TVSixColumnGridTemplate
    
    private var _collectionView:    UICollectionView = UICollectionView(frame: CGRectZero, collectionViewLayout: UICollectionViewFlowLayout())
    private var _artworkDataSource: ChannelArtworkImageDataSource = ChannelArtworkImageDataSource()
    private var _sortedChannels:    [Channel] = []
    
    weak var delegate:              ChannelListViewControllerDelegate?
    
    var server: AudioAddictServer?
    {
        didSet
        {
            _artworkDataSource.server = server
        }
    }
    
    var channels: [Channel] = []
    {
        didSet
        {
            _sortedChannels = self.channels.sort({ $0.name < $1.name })
            _collectionView.reloadData()
        }
    }
    
    // MARK: UIViewController
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        let collectionViewLayout = _collectionView.collectionViewLayout as! UICollectionViewFlowLayout
        let layoutTemplate = ChannelListViewController.LayoutTemplate
        collectionViewLayout.itemSize = CGSize(width: layoutTemplate.unfocusedContentWidth, height: layoutTemplate.unfocusedContentWidth)
        collectionViewLayout.minimumInteritemSpacing = layoutTemplate.horizontalSpacing
        collectionViewLayout.minimumLineSpacing = layoutTemplate.minimumVerticalSpacing
        collectionViewLayout.sectionInset = TVContentSafeZoneInsets
        
        _collectionView.delegate = self
        _collectionView.dataSource = self
        _collectionView.registerClass(ChannelCollectionViewCell.self, forCellWithReuseIdentifier: ChannelListViewController.CollectionViewReuseIdentifier)
        self.view.addSubview(_collectionView)
    }
    
    override func viewDidLayoutSubviews()
    {
        super.viewDidLayoutSubviews()
        _collectionView.frame = self.view.bounds
    }
    
    // MARK: UICollectionViewDataSource
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
    {
        return _sortedChannels.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell
    {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(
            ChannelListViewController.CollectionViewReuseIdentifier,
            forIndexPath: indexPath)
            as! ChannelCollectionViewCell
        
        let channel = _sortedChannels[indexPath.row]
        cell.channel = _sortedChannels[indexPath.row]
        
        let sizeDimensions = ChannelListViewController.LayoutTemplate.unfocusedContentWidth
        let size = CGSize(width: sizeDimensions, height: sizeDimensions)
        _artworkDataSource.loadChannelArtworkImage(channel, size: size) { (channelImage: UIImage?, error: NSError?) -> (Void) in
            dispatch_async(dispatch_get_main_queue()) {
                if (cell.channel?.identifier == channel.identifier) {
                    cell.channelImage = channelImage
                }
            }
        }
        
        return cell
    }
    
    // MARK: UICollectionViewDelegate
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath)
    {
        let channel = _sortedChannels[indexPath.row]
        self.delegate?.channelListDidSelectChannel(self, channel: channel)
    }
}
