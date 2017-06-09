//
//  NSDateAdditions.swift
//  di.fm
//
//  Created by Charles Magahern on 5/8/16.
//  Copyright © 2016 zanneth. All rights reserved.
//

import Foundation

extension Date
{
    fileprivate static let RFC3339DateFormatter: DateFormatter = {
        var formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()

    init(rfc3339string: String)
    {
        self.init(timeIntervalSinceReferenceDate: Date.RFC3339DateFormatter.date(from: rfc3339string)!.timeIntervalSinceReferenceDate)
    }
}
