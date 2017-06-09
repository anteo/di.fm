//
//  NSErrorAdditions.swift
//  di.fm
//
//  Created by Charles Magahern on 12/31/15.
//  Copyright © 2015 XION. All rights reserved.
//

import Foundation

struct DIError : LocalizedError
{
    enum ErrorCode
    {
        case unknown
        case connectionError
        case configurationError
        case authenticationError
        case invalidAuthCredentials
    }
    
    let code: ErrorCode
    var debugDescription: String? = nil
    
    init(code: ErrorCode) {
        self.code = code
    }
    
    public var errorDescription: String?
    {
        switch self.code {
        case .unknown:
            return NSLocalizedString("UNKNOWN_ERROR", comment: "")
        case .connectionError:
            return NSLocalizedString("CONNECTION_ERROR", comment: "")
        case .configurationError:
            return NSLocalizedString("CONFIGURATION_ERROR", comment: "")
        case .authenticationError:
            return NSLocalizedString("AUTH_ERROR_NOT_AUTHENTICATED", comment: "")
        case .invalidAuthCredentials:
            return NSLocalizedString("AUTH_ERROR_USERNAME_OR_PASSWORD", comment: "")
        }
    }
}
