//
//  User+Authentication.swift
//  VillageCore
//
//  Created by Rob Feldmann on 2/9/19.
//  Copyright © 2019 Dynamit. All rights reserved.
//

import Foundation
import Promises

// MARK: - AuthenticationService

extension User {
    
    public func validateIdentity() -> Promise<User> {
        return AuthenticationService.validateIdentity(user: self)
    }
    
    public func login() -> Promise<User> {
        return AuthenticationService.login(user: self)
    }
    
    public func getDetails() -> Promise<User> {
        return AuthenticationService.getDetails(user: self)
    }
    
    public func getSecurityPolicies() -> Promise<User> {
        return AuthenticationService.getSecurityPolicies(user: self)
    }
    
    public func loginWithDetails() -> Promise<User> {
        return firstly {
            self.login()
        }.then { user in
            user.getDetails()
        }.then { user in
            user.getSecurityPolicies()
        }
    }
    
    public func initiateResetPassword() -> Promise<User> {
        return AuthenticationService.initiateResetPassword(user: self)
    }
    
    public static func invite(emailAddress: String) -> Promise<Void> {
        return AuthenticationService.invite(emailAddress: emailAddress)
    }
    
    @discardableResult public func logout() -> Promise<User> {
        func resetUserToGuest() -> User {
            self.removeAll()
            User.current = User.guest
            return User.current
        }
        
        return firstly {
            AuthenticationService.logout(user: self)
        }.then {
            return resetUserToGuest()
        }.recover { _ in
            return resetUserToGuest()
        }
    }
    
}

// MARK: DirectoryService

extension User {
    
    public func getPerson() -> Promise<Person> {
        return DirectoryService.getDetails(for: self)
    }
    
}
