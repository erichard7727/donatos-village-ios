//
//  User.swift
//  VillageCore
//
//  Created by Rob Feldmann on 2/9/19.
//  Copyright © 2019 Dynamit. All rights reserved.
//

import Foundation

public extension Notification.Name {
    public struct User {
        
        /// Posted whenever User.current changes.
        public static let CurrentUserDidChange = Notification.Name(rawValue: "com.dynamit.villageCore.notification.name.user.currentUserDidChange")
    }
}

public class User {
    
    public static var current: User = { return getSaved() }() {
        didSet {
            save(current)
        }
    }
    
    public let identity: String
    
    private init() {
        self.identity = ""
    }
    
    public init(identity: String) {
        self.identity = identity
    }
    
    public static var guest: User = { return User() }()
    
    public var isGuest: Bool {
        return self === User.guest
    }
    
}

fileprivate extension User {
    
    private static func getSaved() -> User {
        guard let loggedInIdentity = UserDefaults.standard.string(forKey: "loggedInIdentity") else {
            // no previous-login exists, return guest user
            return User.guest
        }
        // create a User object with the stored identity (if one exists),
        // the corresponding keychain will be automatically populated
        return User(identity: loggedInIdentity)
    }
    
    private static func save(_ user: User) {
        if user.isGuest {
            UserDefaults.standard.set(nil, forKey: "loggedInIdentity")
        } else {
            UserDefaults.standard.set(user.identity, forKey: "loggedInIdentity")
        }
        NotificationCenter.default.post(name: Notification.Name.User.CurrentUserDidChange, object: user)
    }
    
}
