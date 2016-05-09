//
//  ChannelFilter.swift
//  di.fm
//
//  Created by Charles Magahern on 4/26/16.
//

import Foundation

struct ChannelFilter
{
    var identifier:         Int = 0
    var display:            Bool = false
    var key:                String = ""
    var meta:               Bool = false
    var name:               String = ""
    var networkIdentifier:  Int = 0
    var position:           Int = 0
    var spriteURL:          AudioAddictURL = AudioAddictURL()
    var channels:           [Channel] = []
    
    init()
    {}
    
    init(_ dict: NSDictionary)
    {
        if let identifier = dict["id"] as? NSNumber {
            self.identifier = identifier.integerValue
        }
        if let display = dict["display"] as? NSNumber {
            self.display = display.boolValue
        }
        if let key = dict["key"] as? NSString {
            self.key = String(key)
        }
        if let meta = dict["meta"] as? NSNumber {
            self.meta = meta.boolValue
        }
        if let name = dict["name"] as? NSString {
            self.name = String(name)
        }
        if let networkIdentifier = dict["network_id"] as? NSNumber {
            self.networkIdentifier = networkIdentifier.integerValue
        }
        if let position = dict["position"] as? NSNumber {
            self.position = position.integerValue
        }
        if let spriteURL = dict["sprite"] as? NSString {
            self.spriteURL = AudioAddictURL(spriteURL as String)
        }
        if let channelObjs = dict["channels"] as? NSArray {
            var channels: [Channel] = []
            for channelObj in channelObjs {
                if let channelDict = channelObj as? NSDictionary {
                    channels.append(Channel(channelDict))
                }
            }
            
            self.channels = channels
        }
    }
    
    func isStyleFilter() -> Bool
    {
        return Set([
            5,  // Trance
            7,  // Dance
            6,  // House
            16, // Lounge
            9,  // Chillout
            8,  // Techno
            65, // Bass
            15, // Ambient
            88, // Deep
            19, // Classic
            11, // Vocal
            12  // Hard
        ]).contains(self.identifier)
    }
    
    func isHidden() -> Bool
    {
        // no idea what these are, but don't show them
        return Set([
            67, // UMF
            69  // Sankeys
        ]).contains(self.identifier)
    }
}
