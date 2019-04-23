//
//  Person+Directory.swift
//  VillageCore
//
//  Created by Rob Feldmann on 3/14/19.
//  Copyright © 2019 Dynamit. All rights reserved.
//

import Foundation
import Promises
import SwiftyJSON

// MARK: - Directory Service

extension Person {
    
    public func getDetails() -> Promise<Person> {
        return DirectoryService.getDetails(for: self)
    }
    
    public func updateDetails(avatarData: Data?) -> Promise<Person> {
        return DirectoryService.updateDetails(for: self, avatarData: avatarData)
    }

}

public extension Sequence where Element == Person {
    
    /// Extends typealias `People` to fetch a directory.
    ///
    /// - Parameter page: The page of results to fetch. Default == first.
    /// - Returns: A list of `People`
    public static func getDirectory(page: Int = 1) -> Promise<People> {
        return DirectoryService.getDirectory(page: page)
    }
    
    /// Extends typealias `People` to search a directory.
    ///
    /// - Parameters:
    ///   - term: The user's search term
    ///   - page: The page of results to fetch. Default == first.
    /// - Returns: A list of `People`
    public static func search(for term: String, page: Int = 1) -> Promise<People> {
        return DirectoryService.search(for: term, page: page)
    }
    
}

// MARK: - Kudos Service

extension Person {
    
    public func kudosStream(page: Int = 1) -> Promise<Kudos> {
        return KudosService.getKudosStream(for: self, page: page)
    }
    
    public func kudosReceived(achievement: Achievement? = nil, page: Int = 1) -> Promise<Kudos> {
        return KudosService.getKudosReceived(for: self, achievement: achievement, page: page)
    }
    
    public func kudosGiven(achievement: Achievement? = nil, page: Int = 1) -> Promise<Kudos> {
        return KudosService.getKudosGiven(for: self, achievement: achievement, page: page)
    }
    
    public func achievements(page: Int = 1) -> Promise<Achievements> {
        return KudosService.getAchievements(for: self, page: page)
    }
    
    public func giveKudo(for achievement: Achievement, points: Int = 1, reason: String) -> Promise<Void> {
        return KudosService.giveKudo(to: self, for: achievement, points: points, comment: reason)
    }
    
}

// MARK: - Sreams Service

extension Person {
    
    public func send(message: String, to stream: Stream) -> Promise<Message> {
        return StreamsService.sendMessage(body: message, from: self, to: stream)
    }
    
}
