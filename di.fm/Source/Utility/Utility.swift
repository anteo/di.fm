//
//  Utility.swift
//  di.fm
//
//  Created by Charles Magahern on 5/8/16.
//

import Foundation

var __RFC3339DateFormatter:   NSDateFormatter? = nil
var __onceToken:              dispatch_once_t = 0

func DateFromRFC3339String(str: String) -> NSDate?
{
    dispatch_once(&__onceToken) {
        __RFC3339DateFormatter = NSDateFormatter()
        __RFC3339DateFormatter!.locale = NSLocale(localeIdentifier: "en_US_POSIX")
        __RFC3339DateFormatter!.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        __RFC3339DateFormatter!.timeZone = NSTimeZone(forSecondsFromGMT: 0)
    }
    
    return __RFC3339DateFormatter!.dateFromString(str)
}
