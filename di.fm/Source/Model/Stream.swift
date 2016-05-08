//
//  Stream.swift
//  di.fm
//
//  Created by Charles Magahern on 5/7/16.
//

import Foundation

struct Stream
{
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
