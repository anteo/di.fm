//
//  CredentialsStore.swift
//  di.fm
//
//  Created by Charles Magahern on 5/11/16.
//

import Foundation

class CredentialsStore
{
    private var _keychainItem: KeychainItemWrapper = KeychainItemWrapper(identifier: "com.zanneth.di.fm", accessGroup: nil)
    
    var username: String?
    {
        get
        {
            return _keychainItem.objectForKey(kSecAttrAccount) as? String
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
            return _keychainItem.objectForKey(kSecValueData) as? String
        }
        
        set(newPassword)
        {
            _keychainItem.setObject(newPassword, forKey: kSecValueData)
        }
    }
    
    func hasCredentials() -> Bool
    {
        return (self.username?.characters.count > 0 && self.password?.characters.count > 0)
    }
    
    func reset()
    {
        _keychainItem.resetKeychainItem()
    }
}
