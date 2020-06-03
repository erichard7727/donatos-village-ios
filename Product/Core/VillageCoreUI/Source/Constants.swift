//
//  Constants.swift
//  VillageCore
//
//  Created by Rob Feldmann on 2/9/19.
//  Copyright © 2019 Dynamit. All rights reserved.
//

import Foundation

func VLG_SYSTEM_VERSION_LESS_THAN(_ version: String) -> Bool {
    return UIDevice.current.systemVersion.compare(version, options: String.CompareOptions.numeric) == .orderedAscending
}

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
        static let kudosPointsEnabled = false

        static let contentLibraryEnabled = false
        static let achievementsEnabled = false
        static let manageNoticesEnabled = false
        static let createGroupsEnabled = true

        static let disableLargeTitles: Bool = {
            let isiOS12 = VLG_SYSTEM_VERSION_LESS_THAN("13")
            if !isiOS12 && VLG_SYSTEM_VERSION_LESS_THAN("13.2") {
                // Disable large titles
                return true
            } else {
                // Enable large titles
                return false
            }
        }()

        static let hidesSearchBarWhenScrolling: Bool = {
            let isiOS12 = VLG_SYSTEM_VERSION_LESS_THAN("13")
            if !isiOS12 && VLG_SYSTEM_VERSION_LESS_THAN("13.2") {
                // Disable hidibg when scrolling
                return false
            } else {
                // Enable hidibg when scrolling
                return true
            }
        }()
    }
    
    struct URL {
        static let schedulerLink = Foundation.URL(string: "https://schedule.donatos.com/schedule/index")!
    }
}
