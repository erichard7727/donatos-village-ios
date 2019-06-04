//
//  Achievements+Services.swift
//  VillageCore
//
//  Created by Rob Feldmann on 4/17/19.
//  Copyright © 2019 Dynamit. All rights reserved.
//

import Foundation
import Promises

public extension Sequence where Element == Achievement {
    
    /// Extends typealias `Achievements` to fetch the achievements
    /// the authenticated user can give kudos for.
    ///
    /// - Parameter page: The page of results to fetch. Default == first.
    /// - Returns: A list of `Achievements`
    static func givable(page: Int = 1) -> Promise<Achievements> {
        return KudosService.givableAchievements(page: page)
    }
    
}
