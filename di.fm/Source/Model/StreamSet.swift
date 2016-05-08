//
//  StreamSet.swift
//  di.fm
//
//  Created by Charles Magahern on 5/7/16.
//

import Foundation

struct StreamSet
{
    var identifier:         Int = 0
    var networkIdentifier:  Int = 0
    var name:               String = ""
    var key:                String = ""
    var description:        String = ""
    var streamlist:         StreamList = StreamList()
    
    init()
    {}
    
    init(_ dict: NSDictionary)
    {
        if let identifier = dict["id"] as? NSNumber {
            self.identifier = identifier.integerValue
        }
        if let networkIdentifier = dict["network_id"] as? NSNumber {
            self.networkIdentifier = networkIdentifier.integerValue
        }
        if let name = dict["name"] as? NSString {
            self.name = String(name)
        }
        if let key = dict["key"] as? NSString {
            self.key = String(key)
        }
        if let description = dict["description"] as? NSString {
            self.description = String(description)
        }
        if let streamlistDict = dict["streamlist"] as? NSDictionary {
            self.streamlist = StreamList(streamlistDict)
        }
    }
}
