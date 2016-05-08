//
//  Station.swift
//  di.fm
//
//  Created by Charles Magahern on 4/26/16.
//

import Foundation

struct Station
{
    enum Quality : String
    {
        case PublicHigh = "public3"             // MP3/96kbps
        case PublicMedium = "public2"           // AAC-HE/40kbps
        case PublicLow = "public5"              // WMA/40kbps
        
        // Premium-only quality types
        case PremiumHigh = "premium_high"       // MP3/256kbps
        case PremiumDefault = "premium"         // MP3/128kbps or AAC-HE/128kbps
        case PremiumMedium = "premium_medium"   // AAC-HE/64kbps
        case PremiumLow = "premium_low"         // AAC-HE/40kbps
        case PremiumWMA = "premium_wma"         // WMA/128kbps
        case PremiumWMALow = "premium_wma_low"  // WMA/64kbps
    }
    
    var identifier:     Int     = 0
    var quality:        Quality = .PublicHigh
    var key:            String  = ""
    var name:           String  = ""
    var playlistURL:    NSURL   = NSURL()
    
    init()
    {}
    
    init(_ dict: NSDictionary)
    {
        if let identifier = dict["id"] as? NSNumber {
            self.identifier = identifier.integerValue
        }
        
        if let key = dict["key"] as? NSString {
            self.key = String(key)
        }
        
        if let name = dict["name"] as? NSString {
            self.name = String(name)
        }
        
        if let playlistURLString = dict["playlist"] as? NSString {
            let playlistURL = NSURL(string: String(playlistURLString))
            if (playlistURL != nil) {
                self.playlistURL = playlistURL!
            }
        }
    }
}
