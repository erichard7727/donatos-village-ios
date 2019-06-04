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
    
    /// Returns a `ContentLibrary` or directory for the given parent item.
    ///
    /// - Returns: The directory or `ContentLibrary`
    public func getDirectory() -> Promise<ContentLibrary> {
        return ContentLibraryService.getDirectory(item: self)
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
    /// - Returns: A ContentLibrary or `[ContentLibraryItem]`
    static func getRootDirectory(page: Int = 1) -> Promise<ContentLibrary> {
        return ContentLibraryService.getRootDirectory(page: page)
    }
    
}
