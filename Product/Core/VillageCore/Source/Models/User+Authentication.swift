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
    
    public enum ValidateIdentityNextStep {
        case enterPassword(User)
        case confirmEmail(User)
        case createAccount(User)
        
        internal init(_ authServiceNextStep: AuthenticationService.ValidateIdentityNextStep) {
            switch authServiceNextStep {
            case .enterPassword(let user):
                self = .enterPassword(user)
            case .confirmEmail(let user):
                self = .confirmEmail(user)
            case .createAccount(let user):
                self = .createAccount(user)
            }
        }
    }
    
    public enum DomainInitiationMode {
        case invitation
        case confirmation
        
        internal var authServiceMode: AuthenticationService.DomainInitiationMode {
            switch self {
            case .invitation: return .invitation
            case .confirmation: return .confirmation
            }
        }
    }
    
    public func validateIdentity() -> Promise<ValidateIdentityNextStep> {
        return firstly {
            AuthenticationService.validateIdentity(user: self)
        }.then { User.ValidateIdentityNextStep.init($0) }
    }
    
    public static func initiateDomatin(mode: DomainInitiationMode, emailAddress: String) -> Promise<Void> {
        return AuthenticationService.initiateDomatin(mode: mode.authServiceMode, emailAddress: emailAddress)
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
        func resetUserToGuest() throws -> User {
            try self.keychain?.removeAll()
            User.current = User.guest
            return User.current
        }
        
        return firstly {
            AuthenticationService.logout(user: self)
        }.then {
            return try resetUserToGuest()
        }.recover { _ in
            return try resetUserToGuest()
        }
    }
    
}

// MARK: DirectoryService

extension User {
    
    public func getPerson() -> Promise<Person> {
        return DirectoryService.getDetails(for: self)
    }
    
}
