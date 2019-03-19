//
//  AuthenticationService.swift
//  VillageCore
//
//  Created by Rob Feldmann on 2/9/19.
//  Copyright © 2019 Dynamit. All rights reserved.
//

import Foundation
import Promises
import SwiftyJSON

enum AuthenticationServiceError: Error {
    case invalidIdentity
    case passwordNotSet
}

struct AuthenticationService {
    
    private init() { }
    
    static func validateIdentity(user: User) -> Promise<User> {
        return firstly {
            let validate = VillageCoreAPI.validateIdentity(
                identity: user.identity
            )
            return VillageService.shared.request(target: validate)
        }.then { (json: JSON) -> User in
            user.emailAddress = try json["emailAddress"].string.orThrow(AuthenticationServiceError.invalidIdentity)
            return user
        }
    }
    
    static func login(user: User) -> Promise<User> {
        guard let password = user.password else {
            return Promise(AuthenticationServiceError.passwordNotSet)
        }
        
        return firstly {
            let login = VillageCoreAPI.login(
                identity: user.identity,
                password: password,
                prefetch: nil,
                pushType: "apns",
                pushToken: nil,
                appPlatform: "iOS",
                appVersion: "1.0"
            )
            return VillageService.shared.request(target: login)
        }.then { json in
            return user.update(from: json)
        }
    }
    
    static func getDetails(user: User) -> Promise<User> {
        return firstly {
            VillageService.shared.request(target: VillageCoreAPI.me)
        }.then { json in
            return user.update(from: json)
        }
    }
    
    static func getSecurityPolicies(user: User) -> Promise<User> {
        return firstly {
            VillageService.shared.request(target: VillageCoreAPI.securityPolicies(userId: user.personId.description))
        }.then { json in
            user.securityPolicies = SecurityPolicies(from: json)
            return Promise(user)
        }
    }
    
    static func initiateResetPassword(user: User) -> Promise<User> {
        return firstly {
            let initiateResetPassword = VillageCoreAPI.initiateResetPassword(
                emailAddress: user.identity
            )
            return VillageService.shared.request(target: initiateResetPassword)
        }.then { (json: JSON) -> User in
            user.emailAddress = try json["emailAddress"].string.orThrow(AuthenticationServiceError.invalidIdentity)
            return user
        }
    }
    
    static func invite(emailAddress: String) -> Promise<Void> {
        return VillageService.shared.request(target: VillageCoreAPI.inviteUser(email: emailAddress)).asVoid()
    }
    
    static func logout(user: User) -> Promise<Void> {
        return VillageService.shared.request(target: VillageCoreAPI.logout).asVoid()
    }
    
}

// MARK: - SwiftyJSON Extensions

fileprivate extension User {
    
    func update(from response: JSON) -> User {
        
        if response["user"].exists() {
            self.personId = {
                if response["user"]["personId"].exists() {
                    return response["user"]["personId"].int64Value
                } else {
                    return response["user"]["id"].int64Value
                }
            }()
            self.emailAddress = response["user"]["emailAddress"].stringValue
            self.displayName = response["user"]["displayName"].stringValue
            self.deactivated = response["user"]["deactivated"].boolValue
            self.lastLoginDate = response["user"]["lastLoginDate"].string
            self.lastUpdatedDate = response["user"]["lastUpdatedDate"].string
        } else if response["person"].exists() {
            self.personId = response["person"]["id"].int64Value
            // firstName
            // lastName
            // jobTitle
            self.displayName = response["person"]["displayName"].stringValue
            self.avatarURL = response["person"]["avatar"]["url"].url
            self.emailAddress = response["person"]["emailAddress"].stringValue
            // phone
            // twitter
            self.deactivated = response["person"]["deactivated"].boolValue
            self.lastUpdatedDate = response["person"]["lastUpdatedDate"].string
        } else {
            assertionFailure()
        }
        
        return self
    }
}

fileprivate extension SecurityPolicies {
    
    init(from response: JSON) {
        // Convert an array of service policy IDs (Strings) into an array of SecurityPolicies
        let policies = response["policies"].arrayValue.compactMap({ SecurityPolicies(securityPolicyID: $0["id"].stringValue) })
        
        // Initialize a single SecurityPolicies instance from the array of individual SecurityPolicies
        self = SecurityPolicies.combining(policies)
    }

}
