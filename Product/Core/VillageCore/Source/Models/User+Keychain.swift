//
//  User+Keychain.swift
//  VillageCore
//
//  Created by Rob Feldmann on 2/9/19.
//  Copyright © 2019 Dynamit. All rights reserved.
//

import Foundation

// MARK: - Keychain-Backed Properties

extension User {
    
    private var keychain: UserDefaults {
        #warning("TODO - replace user defaults for keychain")
        return UserDefaults.standard
    }
    
    public var diagnosticId: String {
        get {
            guard let diagnosticId = keychain.string(forKey: "diagnosticId") else {
                let uuid = UUID().uuidString
                keychain.setValue(uuid, forKey: "diagnosticId")
                keychain.synchronize()
                return uuid
            }
            return diagnosticId
        }
    }
    
    public var password: String? {
        get { return keychain.string(forKey: "password") }
        set { keychain.setValue(newValue, forKey: "password") }
    }
    
    public var xsrfToken: String? {
        get { return keychain.string(forKey: "xsrfToken") }
        set { keychain.setValue(newValue, forKey: "xsrfToken") }
    }
    
    public var personId: Int64 {
        get {
            guard let personId = keychain.object(forKey: "personId") as? Int64 else {
                assertionFailure("Programmer error! Property not available until login is called for the first time.")
                return -1
            }
            return personId
        }
        set {
            keychain.set(newValue, forKey: "personId")
        }
    }
    
    public var emailAddress: String {
        get {
            guard let emailAddress = keychain.string(forKey: "emailAddress") else {
                assertionFailure("Programmer error! Property not available until login is called for the first time.")
                return ""
            }
            return emailAddress
        }
        set {
            keychain.set(newValue, forKey: "emailAddress")
        }
    }
    
    public var displayName: String {
        get {
            guard let displayName = keychain.string(forKey: "displayName") else {
                return "Guest"
            }
            return displayName
        }
        set {
            keychain.set(newValue, forKey: "displayName")
        }
    }
    
    public var avatarURL: URL? {
        get {
            guard let avatarURL = keychain.url(forKey: "avatarURL") else {
                return nil
            }
            return avatarURL
        }
        set {
            keychain.set(newValue, forKey: "avatarURL")
        }
    }
    
    public var deactivated: Bool {
        get {
            guard keychain.object(forKey: "deactivated") != nil else {
                // default value
                return false
            }
            return keychain.bool(forKey: "deactivated")
        }
        set {
            keychain.set(newValue, forKey: "deactivated")
        }
    }
    
    public var lastLoginDate: String? {
        get {
            return keychain.string(forKey: "lastLoginDate")
        }
        set {
            keychain.set(newValue, forKey: "lastLoginDate")
        }
    }
    
    public var lastUpdatedDate: String? {
        get {
            return keychain.string(forKey: "lastUpdatedDate")
        }
        set {
            keychain.set(newValue, forKey: "lastUpdatedDate")
        }
    }
    
    public var securityPolicies: SecurityPolicies {
        get {
            let rawValue = (keychain.object(forKey: "securityPolicies") as? NSNumber)?.int64Value ?? 0
            return SecurityPolicies(rawValue: rawValue)
        }
        set {
            keychain.set(NSNumber(value: newValue.rawValue), forKey: "securityPolicies")
        }
    }
    
    public func removeAll() {
        let keys: [String] = [
            "diagnosticId",
            "password",
            "xsrfToken",
            "personId",
            "emailAddress",
            "displayName",
            "avatarURL",
            "deactivated",
            "lastLoginDate",
            "lastUpdatedDate",
        ]
        keys.forEach({ keychain.removeObject(forKey: $0) })
    }
    
}
