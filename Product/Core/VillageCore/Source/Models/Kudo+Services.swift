//
//  Kudo+Services.swift
//  VillageCore
//
//  Created by Rob Feldmann on 4/13/19.
//  Copyright © 2019 Dynamit. All rights reserved.
//

import Foundation
import Promises

public extension Kudo {

    func flag() -> Promise<Kudo> {
        return KudosService.flag(self)
    }

}

public extension Sequence where Element == Kudo {
    
    /// Extends typealias `Kudos` to fetch the leaderboard.
    ///
    /// - Parameter page: The page of results to fetch. Default == first.
    /// - Returns: A list of `People`
    static func leaderboard(page: Int = 1) -> Promise<People> {
        return KudosService.getLeaderboard(page: page)
    }
    
    /// Extends typealias `Kudos` to fetch the leaderboard for the past week.
    ///
    /// - Parameters:
    ///   - page: The page of results to fetch. Default == first.
    /// - Returns: A list of `People`
    static func weeklyLeaderboard(page: Int = 1) -> Promise<People> {
        return KudosService.getWeeklyLeaderboard(page: page)
    }
    
}
