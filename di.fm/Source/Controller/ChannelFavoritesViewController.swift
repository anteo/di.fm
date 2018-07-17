//
//  ChannelFilterViewController.swift
//  di.fm
//
//  Created by Charles Magahern on 5/8/16.
//  Copyright © 2016 zanneth. All rights reserved.
//

import Foundation
import UIKit

class ChannelFavoritesViewController : UIViewController
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
            self.title = NSLocalizedString("FAVORITES_TAB", comment: "")
            self.channelListViewController.sorted = true
            if (server?.authenticatedUser != nil) {
                for channel in self.channelFilter?.channels ?? [] {
                    if (server!.authenticatedUser!.favoriteChannelIDs.contains(channel.identifier)) {
                        self.channelListViewController.channels.append(channel)
                    }
                }
            }
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
