//
//  Stream.swift
//  di.fm
//
//  Created by Charles Magahern on 5/7/16.
//

import Foundation

struct Stream
{
    enum Quality : String {
        case Public1        = "public1"         // 64kbps aac
        case Public2        = "public2"         // 40kbps aac
        case Public3        = "public3"         // 96kbps mp3
        case PremiumLow     = "premium_low"     // 40kbps aac
        case PremiumMedium  = "premium_medium"  // 64kbps aac
        case Premium        = "premium"         // 128kbps aac
        case PremiumHigh    = "premium_high"    // 256kbps mp3
    }
    
    var identifier:     Int = 0
    var url:            NSURL = NSURL()
    var format:         String = ""
    var bitrate:        UInt = 0
    
    init()
    {}
    
    init(_ dict: NSDictionary)
    {
        if let identifier = dict["identifier"] as? NSNumber {
            self.identifier = identifier.integerValue
        }
        if let url = dict["url"] as? NSString {
            self.url = NSURL(string: url as String)!
        }
        if let format = dict["format"] as? NSString {
            self.format = String(format)
        }
        if let bitrate = dict["bitrate"] as? NSNumber {
            self.bitrate = bitrate.unsignedIntegerValue
        }
    }
}
