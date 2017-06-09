//
//  StreamList.swift
//  di.fm
//
//  Created by Charles Magahern on 5/7/16.
//  Copyright © 2016 zanneth. All rights reserved.
//

import Foundation

struct StreamList
{
    var identifier:         Int = 0
    var name:               String = ""
    var channelIDToStreams: [Int : [Stream]] = [:]
    
    init()
    {}
    
    init(_ dict: NSDictionary)
    {
        if let identifier = dict["id"] as? NSNumber {
            self.identifier = identifier.intValue
        }
        if let name = dict["name"] as? NSString {
            self.name = String(name)
        }
        if let channelsArray = dict["channels"] as? NSArray {
            var channelIDToStreams: [Int : [Stream]] = [:]
            
            for channelObj in channelsArray {
                if let channelDict = channelObj as? NSDictionary {
                    let channelID = (channelDict["id"] as! NSNumber).intValue
                    channelIDToStreams[channelID] = _parseChannelStreams(channelDict)
                }
            }
            
            self.channelIDToStreams = channelIDToStreams
        }
    }
    
    // MARK: Internal
    
    internal func _parseChannelStreams(_ channelDict: NSDictionary) -> [Stream]
    {
        var streams: [Stream] = []
        
        if let streamsArray = channelDict["streams"] as? NSArray {
            for streamObj in streamsArray {
                if let streamDict = streamObj as? NSDictionary {
                    streams.append(Stream(streamDict))
                }
            }
        }
        
        return streams
    }
}
