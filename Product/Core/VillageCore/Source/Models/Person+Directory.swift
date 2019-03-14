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

}

public extension Sequence where Element == Person {
    
    /// Extends typealias `People` to fetch a directory.
    ///
    /// - Parameter page: The page of results to fetch. Default == first.
    /// - Returns: A list of `People`
    public static func getDirectory(page: Int = 1) -> Promise<People> {
        return DirectoryService.getDirectory(page: page)
    }
    
}

// MARK: - Kudos Service

extension Person {
    
    public func kudosReceived(page: Int = 1) -> Promise<Kudos> {
        return KudosService.getKudosReceived(for: self, page: page)
    }
    
    public func kudosGiven(page: Int = 1) -> Promise<Kudos> {
        return KudosService.getKudosGiven(for: self, page: page)
    }
    
}
