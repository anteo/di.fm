//
//  Settings.swift
//  di.fm
//
//  Created by Charles Magahern on 7/24/16.
//  Copyright © 2016 zanneth. All rights reserved.
//

import Foundation

class Settings
{
    static let sharedSettings = Settings()
    static let settingsDidChangeNotification = "SettingsDidChangeNotification"
    
    fileprivate var _defaults: UserDefaults = UserDefaults.standard
    
    static fileprivate let _StreamQualityDefaultsKey = "StreamQuality"
    
    var streamQuality: Stream.Quality = .PremiumHigh
    {
        didSet(newValue)
        {
            let savedStreamQuality = _defaults.string(forKey: Settings._StreamQualityDefaultsKey)
            if (savedStreamQuality != newValue.rawValue) {
                _defaults.setValue(newValue.rawValue, forKey: Settings._StreamQualityDefaultsKey)
                _defaults.synchronize()
                
                NotificationCenter.default.post(name: Notification.Name(rawValue: Settings.settingsDidChangeNotification), object: self)
            }
        }
    }
    
    init()
    {
        if let loadedStreamQuality = _defaults.string(forKey: Settings._StreamQualityDefaultsKey) {
            self.streamQuality = Stream.Quality(rawValue: loadedStreamQuality)!
        }
    }
}
