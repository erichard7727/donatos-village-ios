//
//  User+Keychain.swift
//  VillageCore
//
//  Created by Rob Feldmann on 2/9/19.
//  Copyright © 2019 Dynamit. All rights reserved.
//

import Foundation
import KeychainAccess

// MARK: - Keychain-Backed Properties

extension User {
    
    public var diagnosticId: String {
        get {
            guard let diagnosticId = keychain?["diagnosticId"] else {
                let uuid = UUID().uuidString
                keychain?["diagnosticId"] = uuid
                return uuid
            }
            return diagnosticId
        }
    }
    
    public var password: String? {
        get { return keychain?["password"] }
        set { keychain?["password"] = newValue }
    }
    
    public var xsrfToken: String? {
        get { return keychain?["xsrfToken"] }
        set { keychain?["xsrfToken"] = newValue }
    }
    
    public var personId: Int64 {
        get {
            let personIdString = keychain?["personId"] ?? ""
            guard let personId = Int64(personIdString) else {
                assertionFailure("Programmer error! Property not available until login is called for the first time.")
                return -1
            }
            return personId
        }
        set {
            keychain?["personId"] = String(newValue)
        }
    }
    
    public var emailAddress: String {
        get {
            guard let emailAddress = keychain?["emailAddress"] else {
                assertionFailure("Programmer error! Property not available until login is called for the first time.")
                return ""
            }
            return emailAddress
        }
        set {
            keychain?["emailAddress"] = newValue
        }
    }
    
    public var displayName: String {
        get {
            guard let displayName = keychain?["displayName"] else {
                return "Guest"
            }
            return displayName
        }
        set {
            keychain?["displayName"] = newValue
        }
    }
    
    public var avatarURL: URL? {
        get {
            let avatarURLString = keychain?["avatarURL"] ?? ""
            guard let avatarURL = URL(string: avatarURLString) else {
                return nil
            }
            return avatarURL
        }
        set {
            keychain?["avatarURL"] = newValue?.absoluteString
        }
    }
    
    public var deactivated: Bool {
        get {
            let stringValue = keychain?["deactivated"] ?? ""
            guard let isDeactivated = Bool(stringValue) else {
                // default value
                return false
            }
            return isDeactivated
        }
        set {
            keychain?["deactivated"] = String(newValue)
        }
    }
    
    public var lastLoginDate: String? {
        get {
            return keychain?["lastLoginDate"]
        }
        set {
            keychain?["lastLoginDate"] = newValue
        }
    }
    
    public var lastUpdatedDate: String? {
        get {
            return keychain?["lastUpdatedDate"]
        }
        set {
            keychain?["lastUpdatedDate"] = newValue
        }
    }
    
    public var securityPolicies: SecurityPolicies {
        get {
            let securityPoliciesString = keychain?["securityPolicies"] ?? ""
            let rawValue = Int64(securityPoliciesString) ?? 0
            return SecurityPolicies(rawValue: rawValue)
        }
        set {
            keychain?["securityPolicies"] = String(newValue.rawValue)
        }
    }
    
    public var pushToken: String? {
        get {
            return keychain?["pushToken"]
        }
        set {
            keychain?["pushToken"] = newValue
        }
    }
    
}
