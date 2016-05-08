//
//  ViewController.swift
//  di.fm
//
//  Created by Charles Magahern on 4/26/16.
//

import UIKit

class ViewController : UIViewController, UICollectionViewDelegate, UICollectionViewDataSource
{
    private var _collectionView:    UICollectionView = UICollectionView(frame: CGRectZero, collectionViewLayout: UICollectionViewFlowLayout())
    private var _stations:          [Station] = []
    private var _player:            Player = Player()
    
    static private let CollectionViewReuseIdentifier = "CollectionViewReuseIdentifier"
    
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
        _collectionView.registerClass(StationCollectionViewCell.self, forCellWithReuseIdentifier: ViewController.CollectionViewReuseIdentifier)
        self.view.addSubview(_collectionView)
        
        _player.listenKey = "e67d4942e489bd2f3b1b7255"
        
        _reloadStations()
    }
    
    override func viewDidLayoutSubviews()
    {
        super.viewDidLayoutSubviews()
        
        let bounds = self.view.bounds
        _collectionView.frame = bounds
    }
    
    // MARK: UICollectionViewDataSource
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
    {
        return _stations.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell
    {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(ViewController.CollectionViewReuseIdentifier, forIndexPath: indexPath) as! StationCollectionViewCell
        let station = _stations[indexPath.row]
        cell.station = station
        
        return cell
    }
    
    // MARK: UICollectionViewDelegate
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath)
    {
        let station = _stations[indexPath.row]
        _player.currentStation = station
        _player.play()
    }
    
    // MARK: Internal
    
    internal func _reloadStations()
    {
        /*
        _server.fetchStations(.PremiumHigh) { (stations: [Station], error: NSError?) in
            dispatch_async(dispatch_get_main_queue(), { 
                self._stations = stations
                self._collectionView.reloadData()
            })
        }
 */
    }
}
