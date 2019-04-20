//
//  Achievements.swift
//  VillageCore
//
//  Created by Rob Feldmann on 3/14/19.
//  Copyright © 2019 Dynamit. All rights reserved.
//

import Foundation

public typealias Achievements = [Achievement]

public struct Achievement {
    public let id: String
    public let title: String
    public let description: String
    public let pointsCap: Int
    public let userPoints: Int?
    public let enabled: Bool
    public let mediaAttachments: [MediaAttachment]
    public let securityPolicies: SecurityPolicies
}
