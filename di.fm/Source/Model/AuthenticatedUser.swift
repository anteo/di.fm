//
//  AuthenticatedUser.swift
//  di.fm
//
//  Created by Charles Magahern on 5/8/16.
//  Copyright © 2016 zanneth. All rights reserved.
//

import Foundation

struct AuthenticatedUser
{
    var identifier:         Int = 0
    var apiKey:             String = ""
    var email:              String = ""
    var firstName:          String = ""
    var lastName:           String = ""
    var confirmed:          Bool = false
    var fraudulent:         Bool = false
    var activated:          Bool = false
    var listenKey:          String = ""
    var timezone:           TimeZone?
    var favoriteChannelIDs: [Int] = []
    
    init()
    {}
    
    init(_ dict: NSDictionary)
    {
        if let identifier = dict["id"] as? NSNumber {
            self.identifier = identifier.intValue
        }
        if let apiKey = dict["api_key"] as? NSString {
            self.apiKey = String(apiKey)
        }
        if let email = dict["email"] as? NSString {
            self.email = String(email)
        }
        if let firstName = dict["first_name"] as? NSString {
            self.firstName = String(firstName)
        }
        if let lastName = dict["last_name"] as? NSString {
            self.lastName = String(lastName)
        }
        if let confirmed = dict["confirmed"] as? NSNumber {
            self.confirmed = confirmed.boolValue
        }
        if let fraudulent = dict["fraudulent"] as? NSNumber {
            self.fraudulent = fraudulent.boolValue
        }
        if let activated = dict["activated"] as? NSNumber {
            self.activated = activated.boolValue
        }
        if let listenKey = dict["listen_key"] as? NSString {
            self.listenKey = String(listenKey)
        }
        if let timezone = dict["timezone"] as? NSString {
            self.timezone = TimeZone(identifier: timezone as String)
        }
        if let favoriteChannelsArray = dict["network_favorite_channels"] as? NSArray {
            var channelIDs: [Int] = []
            
            for favoriteChannelDict in favoriteChannelsArray as! [NSDictionary] {
                if let channelID = favoriteChannelDict["channel_id"] as? NSNumber {
                    channelIDs.append(channelID.intValue)
                }
            }
            
            self.favoriteChannelIDs = channelIDs
        }
    }
}
