//
//  BatchUpdate.swift
//  di.fm
//
//  Created by Charles Magahern on 5/7/16.
//

import Foundation

class BatchUpdate
{
    private(set) var adNetwork:      String = ""
    private(set) var dateCached:     NSDate?
    private(set) var assets:         [Asset] = []
    private(set) var channelFilters: [ChannelFilter] = []
    private(set) var events:         [Event] = []
    private(set) var streamSets:     [StreamSet] = []
    
    init()
    {}
    
    init(_ dict: NSDictionary)
    {
        if let adNetwork = dict["ad_network"] as? NSString {
            self.adNetwork = String(adNetwork)
        }
        
        if let dateCached = dict["cached_at"] as? NSString {
            self.dateCached = DateFromRFC3339String(dateCached as String)
        }
        
        if let assetsArray = dict["assets"] as? NSArray {
            var assets: [Asset] = []
            for assetObj in assetsArray {
                if let assetDict = assetObj as? NSDictionary {
                    assets.append(Asset(assetDict))
                }
            }
            
            self.assets = assets
        }
        
        if let channelFiltersArray = dict["channel_filters"] as? NSArray {
            var channelFilters: [ChannelFilter] = []
            for channelFilterObj in channelFiltersArray {
                if let channelFilterDict = channelFilterObj as? NSDictionary {
                    channelFilters.append(ChannelFilter(channelFilterDict))
                }
            }
            
            self.channelFilters = channelFilters
        }
        
        if let eventsArray = dict["events"] as? NSArray {
            var events: [Event] = []
            for eventObj in eventsArray {
                if let eventDict = eventObj as? NSDictionary {
                    events.append(Event(eventDict))
                }
            }
            
            self.events = events
        }
        
        if let streamSetsArray = dict["stream_sets"] as? NSArray {
            var streamSets: [StreamSet] = []
            for streamSetObj in streamSetsArray {
                if let streamSetDict = streamSetObj as? NSDictionary {
                    streamSets.append(StreamSet(streamSetDict))
                }
            }
            
            self.streamSets = streamSets
        }
    }
}
