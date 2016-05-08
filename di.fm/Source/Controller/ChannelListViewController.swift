//
//  ChannelListViewController.swift
//  di.fm
//
//  Created by Charles Magahern on 5/8/16.
//

import Foundation
import UIKit

class ChannelListViewController : UIViewController, UICollectionViewDelegate, UICollectionViewDataSource
{
    static private let CollectionViewReuseIdentifier = "CollectionViewReuseIdentifier"
    
    private var _collectionView: UICollectionView = UICollectionView(frame: CGRectZero, collectionViewLayout: UICollectionViewFlowLayout())
    
    var channels: [Channel] = [] {
        didSet
        {
            _collectionView.reloadData()
        }
    }
    
    // MARK: UIViewController
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        let collectionViewLayout = _collectionView.collectionViewLayout as! UICollectionViewFlowLayout
        let layoutTemplate = TVSixColumnGridTemplate
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
        return self.channels.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell
    {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(ChannelListViewController.CollectionViewReuseIdentifier, forIndexPath: indexPath) as! ChannelCollectionViewCell
        cell.channel = self.channels[indexPath.row]
        
        return cell
    }
    
    // MARK: UICollectionViewDelegate
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath)
    {
    }
}
