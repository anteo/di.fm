//
//  Utility.swift
//  di.fm
//
//  Created by Charles Magahern on 5/8/16.
//

import Foundation

var RFC3339DateFormatter: NSDateFormatter? = nil
var onceToken: dispatch_once_t = 0

func DateFromRFC3339String(str: String) -> NSDate?
{
    dispatch_once(&onceToken) {
        RFC3339DateFormatter = NSDateFormatter()
        RFC3339DateFormatter!.locale = NSLocale(localeIdentifier: "en_US_POSIX")
        RFC3339DateFormatter!.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        RFC3339DateFormatter!.timeZone = NSTimeZone(forSecondsFromGMT: 0)
    }
    
    return RFC3339DateFormatter?.dateFromString(str)
}
