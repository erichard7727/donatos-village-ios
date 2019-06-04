//
//  User.swift
//  VillageCore
//
//  Created by Rob Feldmann on 2/9/19.
//  Copyright © 2019 Dynamit. All rights reserved.
//

import Foundation
import KeychainAccess

public extension Notification.Name {
    struct User {
        
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
    
    public private(set) var identity: String
    
    private init() {
        self.identity = ""
    }
    
    public init(identity: String) {
        self.identity = identity
        let bundleIdentifier = Bundle.main.bundleIdentifier!
        self.keychain = Keychain(service: "\(bundleIdentifier).\(identity)").accessibility(.afterFirstUnlock)
    }
    
    public static var guest: User = { return User() }()
    
    public var isGuest: Bool {
        return self === User.guest
    }
    
    internal var keychain: Keychain?
    
}

public extension User {
    func update(from person: Person) {
        self.identity = person.emailAddress
        self.emailAddress = person.emailAddress
        person.displayName.flatMap({ self.displayName = $0 })
        self.avatarURL = person.avatarURL
        self.deactivated = person.deactivated
        User.save(self)
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
        let savedUser = User(identity: loggedInIdentity)
        
        guard !(savedUser.keychain?.allKeys() ?? []).isEmpty else {
            // the user was logged in to a previous version of the app without
            // this keychain or the keychain data is not valid
            UserDefaults.standard.removeObject(forKey: "loggedInIdentity")
            return User.guest
        }
        
        return savedUser
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
