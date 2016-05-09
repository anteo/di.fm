//
//  ChannelFilterViewController.swift
//  di.fm
//
//  Created by Charles Magahern on 5/8/16.
//

import Foundation
import UIKit

class ChannelFilterViewController : UIViewController
{
    private var _channelListViewController: ChannelListViewController = ChannelListViewController()
    
    weak var channelListDelegate: ChannelListViewControllerDelegate?
    {
        didSet
        {
            _channelListViewController.delegate = self.channelListDelegate
        }
    }
    
    var server: AudioAddictServer?
    {
        didSet
        {
            _channelListViewController.server = server
        }
    }
    
    var channelFilter: ChannelFilter?
    {
        didSet
        {
            self.title = self.channelFilter?.name
            _channelListViewController.channels = self.channelFilter?.channels ?? []
        }
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.addChildViewController(_channelListViewController)
        self.view.addSubview(_channelListViewController.view)
    }
    
    override func viewDidLayoutSubviews()
    {
        super.viewDidLayoutSubviews()
        
        let bounds = self.view.bounds
        _channelListViewController.view.frame = bounds
    }
}
