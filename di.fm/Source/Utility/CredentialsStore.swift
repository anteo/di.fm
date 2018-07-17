//
//  CredentialsStore.swift
//  di.fm
//
//  Created by Charles Magahern on 5/11/16.
//  Copyright © 2016 zanneth. All rights reserved.
//

import Foundation

class CredentialsStore
{
    fileprivate var _keychainItem: KeychainItemWrapper = KeychainItemWrapper(identifier: "com.zanneth.di.fm", accessGroup: nil)
    
    var username: String?
    {
        get
        {
            return _keychainItem.object(forKey: kSecAttrAccount) as? String
        }
        
        set(newUsername)
        {
            _keychainItem.setObject(newUsername, forKey: kSecAttrAccount)
        }
    }
    
    var password: String?
    {
        get
        {
            return _keychainItem.object(forKey: kSecValueData) as? String
        }
        
        set(newPassword)
        {
            _keychainItem.setObject(newPassword, forKey: kSecValueData)
        }
    }
    
    func hasCredentials() -> Bool
    {
        let usernameLength = self.username?.count ?? 0
        let passwordLength = self.password?.count ?? 0
        return (usernameLength > 0 && passwordLength > 0)
    }
    
    func reset()
    {
        _keychainItem.resetKeychainItem()
    }
}
