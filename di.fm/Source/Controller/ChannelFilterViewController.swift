//
//  ChannelFilterViewController.swift
//  di.fm
//
//  Created by Charles Magahern on 5/8/16.
//  Copyright © 2016 zanneth. All rights reserved.
//

import Foundation
import UIKit

class ChannelFilterViewController : UIViewController
{
    var channelListViewController: ChannelListViewController = ChannelListViewController()
    
    var server: AudioAddictServer?
    {
        didSet
        {
            self.channelListViewController.server = server
        }
    }
    
    var channelFilter: ChannelFilter?
    {
        didSet
        {
            self.title = self.channelFilter?.name
            self.channelListViewController.channels = self.channelFilter?.channels ?? []
        }
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.addChildViewController(self.channelListViewController)
        self.view.addSubview(self.channelListViewController.view)
    }
    
    override func viewDidLayoutSubviews()
    {
        super.viewDidLayoutSubviews()
        
        let bounds = self.view.bounds
        self.channelListViewController.view.frame = bounds
    }
}
