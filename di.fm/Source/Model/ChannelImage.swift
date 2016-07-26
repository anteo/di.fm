//
//  ChannelImage.swift
//  di.fm
//
//  Created by Charles Magahern on 4/26/16.
//  Copyright © 2016 zanneth. All rights reserved.
//

import Foundation

struct ChannelImage
{
    var defaultURL:             AudioAddictURL = AudioAddictURL()
    var horizontalBannerURL:    AudioAddictURL = AudioAddictURL()
    
    init()
    {}
    
    init(_ dict: NSDictionary)
    {
        if let defaultURL = dict["default"] as? NSString {
            self.defaultURL = AudioAddictURL(defaultURL as String)
        }
        if let horizontalBannerURL = dict["horizontal_banner"] as? NSString {
            self.horizontalBannerURL = AudioAddictURL(horizontalBannerURL as String)
        }
    }
}
