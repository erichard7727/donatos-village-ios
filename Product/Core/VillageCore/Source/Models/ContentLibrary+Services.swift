//
//  ContentLibrary+Services.swift
//  VillageCore
//
//  Created by Rob Feldmann on 4/1/19.
//  Copyright © 2019 Dynamit. All rights reserved.
//

import Foundation
import Promises
import SwiftyJSON

// MARK: - Directory Service

extension ContentLibraryItem {
    
    /// Returns the root `ContentLibrary`
    ///
    /// - Returns: A `Paginated` collection of `ContentLibraryItem`s that can be fetched
    ///            one page at a time as necessary.
    public func getDirectoryPaginated() -> Paginated<ContentLibraryItem> {
        return ContentLibraryService.getDirectoryPaginated(item: self)
    }
    
    /// Creates a `URLRequest` for a non-directory content item (page, link, etc.)
    /// having set the appropriate cookie headers so that the user will be
    /// authenticated correctly to view the material.
    ///
    /// - Returns: The URLRequest if successful.
    /// - Throws: `ContentLibraryServiceError.notDirectory` if it's not a directory
    public func request() throws -> URLRequest {
        return try ContentLibraryService.request(for: self)
    }
    
}

public extension Sequence where Element == ContentLibraryItem {
    
    /// Extends typealias `ContentLibrary` to fetch the top-level,
    /// or root, of the library.
    ///
    /// - Returns: A `Paginated` collection of `ContentLibraryItem`s that can be fetched
    ///            one page at a time as necessary.
    static func getRootDirectoryPaginated() -> Paginated<ContentLibraryItem> {
        return ContentLibraryService.getRootDirectoryPaginated()
    }

    /// Extends typealias `ContentLibrary` to search the entire library.
    ///
    /// - Parameter searchTerm: The search to perform.
    /// - Returns: A `Paginated` collection of `ContentLibraryItem`s that can be fetched
    ///            one page at a time as necessary.
    static func searchLibraryPaginated(_ searchTerm: String) -> Paginated<ContentLibraryItem> {
        return ContentLibraryService.searchLibraryPaginated(searchTerm)
    }
    
}
