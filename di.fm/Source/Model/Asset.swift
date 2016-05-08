//
//  Asset.swift
//  di.fm
//
//  Created by Charles Magahern on 5/7/16.
//

import Foundation

struct Asset
{
    var identifier:     Int = 0
    var name:           String = ""
    var contentHash:    String = ""
    
    init()
    {}
    
    init(_ dict: NSDictionary)
    {
        if let identifier = dict["id"] as? NSNumber {
            self.identifier = identifier.integerValue
        }
        if let name = dict["name"] as? NSString {
            self.name = String(name)
        }
        if let contentHash = dict["content_hash"] as? NSString {
            self.contentHash = String(contentHash)
        }
    }
}
