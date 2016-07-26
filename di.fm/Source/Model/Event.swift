//
//  Event.swift
//  di.fm
//
//  Created by Charles Magahern on 5/7/16.
//  Copyright © 2016 zanneth. All rights reserved.
//

import Foundation

struct Event
{
    var identifier:         Int = 0
    var duration:           NSTimeInterval = 0.0
    var startDate:          NSDate?
    var endDate:            NSDate?
    var artistsTagline:     String = ""
    var descriptionHTML:    String = ""
    var channelIdentifier:  Int = 0
    var title:              String = ""
    var description:        String = ""
    var url:                NSURL = NSURL()
    
    init()
    {}
    
    init(_ dict: NSDictionary)
    {
        if let identifier = dict["id"] as? NSNumber {
            self.identifier = identifier.integerValue
        }
        if let duration = dict["duration"] as? NSNumber {
            self.duration = duration.doubleValue
        }
        if let startDate = dict["start_at"] as? NSString {
            self.startDate = NSDate(rfc3339string: startDate as String)
        }
        if let endDate = dict["end_at"] as? NSString {
            self.endDate = NSDate(rfc3339string: endDate as String)
        }
        if let artistsTagline = dict["artists_tagline"] as? NSString {
            self.artistsTagline = String(artistsTagline)
        }
        if let descriptionHTML = dict["description_html"] as? NSString {
            self.descriptionHTML = String(descriptionHTML)
        }
        if let channelIdentifier = dict["channel_id"] as? NSNumber {
            self.channelIdentifier = channelIdentifier.integerValue
        }
        if let title = dict["title"] as? NSString {
            self.title = String(title)
        }
        if let description = dict["description"] as? NSString {
            self.description = String(description)
        }
        if let url = dict["url"] as? NSString {
            self.url = NSURL(string: url as String)!
        }
    }
}
