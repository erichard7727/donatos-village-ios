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
        static let kudosPluralLong = "Promise in Actions" // Kudos
        static let kudosPluralShort = "PIAs" // Kudos
        static let kudosSingularLong = "Promise in Action" // Kudo
        static let kudosSingularShort = "PIA" // Kudo
        
        static let achievementsEnabled = false
        static let manageNoticesEnabled = false
        static let createGroupsEnabled = true
    }
    
    struct URL {
        static let schedulerLink = Foundation.URL(string: "https://schedule.donatos.com/schedule/index")!
    }
}
