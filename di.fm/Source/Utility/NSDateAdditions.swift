//
//  NSDateAdditions.swift
//  di.fm
//
//  Created by Charles Magahern on 5/8/16.
//

import Foundation

extension NSDate {
    private static var RFC3339DateFormatter:   NSDateFormatter? = nil
    private static var OnceToken:              dispatch_once_t = 0
    
    convenience init(rfc3339string: String)
    {
        dispatch_once(&NSDate.OnceToken) {
            NSDate.RFC3339DateFormatter = NSDateFormatter()
            NSDate.RFC3339DateFormatter!.locale = NSLocale(localeIdentifier: "en_US_POSIX")
            NSDate.RFC3339DateFormatter!.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
            NSDate.RFC3339DateFormatter!.timeZone = NSTimeZone(forSecondsFromGMT: 0)
        }
        
        self.init(timeIntervalSinceReferenceDate: NSDate.RFC3339DateFormatter!.dateFromString(rfc3339string)!.timeIntervalSinceReferenceDate)
    }
}
