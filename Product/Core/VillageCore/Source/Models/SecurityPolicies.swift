//
//  SecurityPolicies.swift
//  VillageCore
//
//  Created by Rob Feldmann on 3/13/19.
//  Copyright © 2019 Dynamit. All rights reserved.
//

import Foundation

/// SecurityPolicies is implemented as a Swift OptionSet which will allow us to
/// cache a user's security permissions as an Int64 and provide
/// a nice API for checking whether a user has certain clearances or not.
///
/// Because OptionSets use bit masks behind the scenes, we can only support a
/// maximum of 63 options [1 << 0 to 1 << 62] (63 options allows room for the last
/// one which is superAdmin. If we ever exceed this many permissions we will
/// have to update this solution.
public struct SecurityPolicies: OptionSet {
    public let rawValue: Int64
    
    /**************************************************************************
     NOTE: Don't forget to add new options to the superAdmin role!!!!!!!!!!!
     **************************************************************************/
    
    public static let manageNotices = SecurityPolicies(rawValue: 1 << 0)
    public static let manageContent = SecurityPolicies(rawValue: 1 << 1)
    public static let manageAchievements = SecurityPolicies(rawValue: 1 << 2)
    public static let manageUsers = SecurityPolicies(rawValue: 1 << 3)
    public static let inviteUsers = SecurityPolicies(rawValue: 1 << 4)
    public static let manageGroups = SecurityPolicies(rawValue: 1 << 5)
    public static let manageLocations = SecurityPolicies(rawValue: 1 << 6)
    public static let manageSettings = SecurityPolicies(rawValue: 1 << 7)
    
    /// The superAdmin role, by default, will contain all of the permissions we know
    /// about. This way we don't have to constantly check for superAdmin + whatever
    /// else throughout our code.
    public static let superAdmin: SecurityPolicies = [
        manageNotices,
        manageContent,
        manageAchievements,
        manageUsers,
        inviteUsers,
        manageGroups,
        manageLocations,
        manageSettings
    ]
    
    public init(rawValue: SecurityPolicies.RawValue) {
        self.rawValue = rawValue
    }
}

extension SecurityPolicies {
    
    public init?(securityPolicyID ID: String) {
        guard let value = SecurityPolicies.policyValueForID(ID) else {
            return nil
        }
        self.init(rawValue: value)
    }
    
    private static func policyValueForID(_ ID: String) -> SecurityPolicies.RawValue? {
        switch ID {
        case "0d74fd6d-7cdd-4f42-aa84-18812796790a":
            return SecurityPolicies.superAdmin.rawValue
            
        case "17f7778d-6ae3-4d0b-b52d-f0e6b473559a":
            return SecurityPolicies.manageNotices.rawValue
            
        case "3870302d-79c8-4fcd-b5b8-3a122d699f97":
            return SecurityPolicies.manageContent.rawValue
            
        case "5d64000e-dd40-415b-a950-9b8cb22f880d":
            return SecurityPolicies.manageAchievements.rawValue
            
        case "6ea12fdd-36c8-412d-9f3c-4b458853be3a":
            return SecurityPolicies.manageUsers.rawValue
            
        case "c63420bc-bedc-44da-9b11-8e423518a622":
            return SecurityPolicies.inviteUsers.rawValue
            
        case "d857f881-c378-4b59-b722-470fafadccc0":
            return SecurityPolicies.manageGroups.rawValue
            
        case "f1a0a20b-6265-4d50-9392-f9e1ce4b7603":
            return SecurityPolicies.manageLocations.rawValue
            
        case "f43eb1be-92b5-4a42-849d-fc7856fad15b":
            return SecurityPolicies.manageSettings.rawValue
            
        default:
            return nil
        }
    }
    
}

extension SecurityPolicies {
    
    public static func combining(_ policies: [SecurityPolicies]) -> SecurityPolicies {
        return policies.reduce([]) { $0.union($1) }
    }
    
}
