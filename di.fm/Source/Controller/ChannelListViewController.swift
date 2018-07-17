//
//  ChannelListViewController.swift
//  di.fm
//
//  Created by Charles Magahern on 5/8/16.
//  Copyright © 2016 zanneth. All rights reserved.
//

import Foundation
import UIKit

protocol ChannelListViewControllerDelegate: class
{
    func channelListDidSelectChannel(_ controller: ChannelListViewController, channel: Channel)
}

class ChannelListViewController : UIViewController, UICollectionViewDelegate, UICollectionViewDataSource
{
    static fileprivate let CollectionViewReuseIdentifier = "CollectionViewReuseIdentifier"
    static fileprivate let LayoutTemplate = TVSixColumnGridTemplate
    
    fileprivate var _collectionView:    UICollectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: UICollectionViewFlowLayout())
    fileprivate var _artworkDataSource: ChannelArtworkImageDataSource = ChannelArtworkImageDataSource()
    fileprivate var _sortedChannels:    [Channel] = []
    
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
            _setAndSortChannels(self.channels)
        }
    }
    
    var sorted: Bool = false
    {
        didSet
        {
            _setAndSortChannels(self.channels)
        }
    }
    
    func _setAndSortChannels(_ channels: [Channel])
    {
        _sortedChannels = sorted ? channels.sorted(by: { $0.name < $1.name }) : channels
        _collectionView.reloadData()
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
        _collectionView.register(ChannelCollectionViewCell.self, forCellWithReuseIdentifier: ChannelListViewController.CollectionViewReuseIdentifier)
        self.view.addSubview(_collectionView)
    }
    
    override func viewDidLayoutSubviews()
    {
        super.viewDidLayoutSubviews()
        _collectionView.frame = self.view.bounds
    }
    
    // MARK: UICollectionViewDataSource
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
    {
        return _sortedChannels.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
    {		
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: ChannelListViewController.CollectionViewReuseIdentifier,
            for: indexPath)
            as! ChannelCollectionViewCell
        
        let channel = _sortedChannels[indexPath.row]
        cell.channel = _sortedChannels[indexPath.row]
        
        let sizeDimensions = ChannelListViewController.LayoutTemplate.unfocusedContentWidth
        let size = CGSize(width: sizeDimensions, height: sizeDimensions)
        _artworkDataSource.loadChannelArtworkImage(channel, size: size) { (channelImage: UIImage?, error: Error?) -> (Void) in
            DispatchQueue.main.async {
                if (cell.channel?.identifier == channel.identifier) {
                    cell.channelImage = channelImage
                }
            }
        }
        
        return cell
    }
    
    // MARK: UICollectionViewDelegate
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath)
    {
        let channel = _sortedChannels[indexPath.row]
        self.delegate?.channelListDidSelectChannel(self, channel: channel)
    }
}
