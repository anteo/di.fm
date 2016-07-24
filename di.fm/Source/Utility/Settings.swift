//
//  Settings.swift
//  di.fm
//
//  Created by Charles Magahern on 7/24/16.
//

import Foundation

class Settings
{
    static let sharedSettings = Settings()
    static let settingsDidChangeNotification = "SettingsDidChangeNotification"
    
    private var _defaults: NSUserDefaults = NSUserDefaults.standardUserDefaults()
    
    static private let _StreamQualityDefaultsKey = "StreamQuality"
    
    var streamQuality: Stream.Quality = .PremiumHigh
    {
        didSet(newValue)
        {
            let savedStreamQuality = _defaults.stringForKey(Settings._StreamQualityDefaultsKey)
            if (savedStreamQuality != newValue.rawValue) {
                _defaults.setValue(newValue.rawValue, forKey: Settings._StreamQualityDefaultsKey)
                _defaults.synchronize()
                
                NSNotificationCenter.defaultCenter().postNotificationName(Settings.settingsDidChangeNotification, object: self)
            }
        }
    }
    
    init()
    {
        if let loadedStreamQuality = _defaults.stringForKey(Settings._StreamQualityDefaultsKey) {
            self.streamQuality = Stream.Quality(rawValue: loadedStreamQuality)!
        }
    }
}
