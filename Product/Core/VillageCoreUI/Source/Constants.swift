//
//  Constants.swift
//  VillageCore
//
//  Created by Rob Feldmann on 2/9/19.
//  Copyright © 2019 Dynamit. All rights reserved.
//

import Foundation

class Constants {
    
    static let bundle = Bundle(for: Constants.self)
    
    private init() { }
    
}

extension Constants {
    struct Settings {
        static let invitationsEnabled = true
        static let directMessagesEnabled = true
        static let kudosEnabled = true
        static let achievementsEnabled = false
        static let manageNoticesEnabled = false
        static let createGroupsEnabled = true
    }
}
