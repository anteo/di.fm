//
//  NSErrorAdditions.swift
//  XIONControlPanel
//
//  Created by Charles Magahern on 12/31/15.
//  Copyright © 2015 XION. All rights reserved.
//

import Foundation

enum ErrorCode : Int {
    case Unknown
    case ConnectionError
    case ConfigurationError
    case AuthenticationError
}

extension NSError {
    private static let ErrorDomain = "com.zanneth.di.fm"
    
    class func difmError(code: ErrorCode) -> NSError
    {
        return self.difmError(code, userInfo: nil)
    }
    
    class func difmError(code: ErrorCode, underlying: NSError?) -> NSError
    {
        var userInfo: [NSObject : AnyObject]? = nil
        if (underlying != nil) {
            userInfo = [
                NSUnderlyingErrorKey : underlying!
            ]
        }
        
        return self.difmError(code, userInfo: userInfo)
    }
    
    class func difmError(code: ErrorCode, description: String) -> NSError
    {
        return self.difmError(code, userInfo: [NSLocalizedDescriptionKey : description])
    }
    
    class func difmError(code: ErrorCode, userInfo: [NSObject : AnyObject]?) -> NSError
    {
        return NSError(domain: ErrorDomain, code: code.rawValue, userInfo: userInfo)
    }
    
    var difmErrorCode: ErrorCode
    {
        return ErrorCode(rawValue: self.code)!
    }
}
