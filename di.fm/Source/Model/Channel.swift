//
//  Channel.swift
//  di.fm
//
//  Created by Charles Magahern on 4/26/16.
//

import Foundation

struct Channel
{
    var identifier:                 Int = 0
    var channelDirector:            String = ""
    var dateCreated:                NSDate?
    var dateUpdated:                NSDate?
    var description:                String = ""
    var descriptionLong:            String = ""
    var descriptionShort:           String = ""
    var key:                        String = ""
    var name:                       String = ""
    var networkIdentifier:          Int = 0
    var oldIdentifier:              Int = 0
    var premiumIdentifier:          Int = 0
    var tracklistServerIdentifier:  Int = 0
    var assetIdentifier:            Int = 0
    var assetURL:                   AudioAddictURL = AudioAddictURL()
    var bannerURL:                  AudioAddictURL = AudioAddictURL()
    var image:                      ChannelImage = ChannelImage()
    
    init()
    {}
    
    init(_ dict: NSDictionary)
    {
        if let identifier = dict["id"] as? NSNumber {
            self.identifier = identifier.integerValue
        }
        if let channelDirector = dict["channel_director"] as? NSString {
            self.channelDirector = String(channelDirector)
        }
        if let dateCreated = dict["created_at"] as? NSString {
            self.dateCreated = NSDate(rfc3339string: dateCreated as String)
        }
        if let dateUpdated = dict["updated_at"] as? NSString {
            self.dateUpdated = NSDate(rfc3339string: dateUpdated as String)
        }
        if let description = dict["description"] as? NSString {
            self.description = String(description)
        }
        if let descriptionLong = dict["description_long"] as? NSString {
            self.descriptionLong = String(descriptionLong)
        }
        if let descriptionShort = dict["description_short"] as? NSString {
            self.descriptionShort = String(descriptionShort)
        }
        if let key = dict["key"] as? NSString {
            self.key = String(key)
        }
        if let name = dict["name"] as? NSString {
            self.name = String(name)
        }
        if let networkIdentifier = dict["network_id"] as? NSNumber {
            self.networkIdentifier = networkIdentifier.integerValue
        }
        if let oldIdentifier = dict["old_id"] as? NSNumber {
            self.oldIdentifier = oldIdentifier.integerValue
        }
        if let premiumIdentifier = dict["premium_id"] as? NSNumber {
            self.premiumIdentifier = premiumIdentifier.integerValue
        }
        if let tracklistServerIdentifier = dict["tracklist_server_id"] as? NSNumber {
            self.tracklistServerIdentifier = tracklistServerIdentifier.integerValue
        }
        if let assetIdentifier = dict["asset_id"] as? NSNumber {
            self.assetIdentifier = assetIdentifier.integerValue
        }
        if let assetURL = dict["asset_url"] as? NSString {
            self.assetURL = AudioAddictURL(assetURL as String)
        }
        if let bannerURL = dict["banner_url"] as? NSString {
            self.bannerURL = AudioAddictURL(bannerURL as String)
        }
        if let imageDict = dict["images"] as? NSDictionary {
            self.image = ChannelImage(imageDict)
        }
    }
}
