//
//  ContentLibraryService.swift
//  VillageCore
//
//  Created by Rob Feldmann on 3/31/19.
//  Copyright © 2019 Dynamit. All rights reserved.
//

import Foundation
import Promises
import SwiftyJSON

enum ContentLibraryServiceError: Error {
    case unknown
    case notDirectory
    case notContentItem
    case invalidUrl
}

struct ContentLibraryService {
    
    private init() { }

    /// Returns the root `ContentLibary`
    ///
    /// - Returns: A `Paginated` collection of `ContentLibraryItem`
    ///            that can be fetched one page at a time as necessary.
    static func getRootDirectoryPaginated() -> Paginated<ContentLibraryItem> {
        return Paginated<ContentLibraryItem>(fetchValues: { (page) -> Promise<PaginatedResults<ContentLibraryItem>> in
            return firstly {
                let rootDirectory = VillageCoreAPI.contentLibraryRoot(page: page)
                return VillageService.shared.request(target: rootDirectory)
            }.then { (json: JSON) -> PaginatedResults<ContentLibraryItem> in
                let rootDirectory = json["content"].arrayValue.compactMap({ ContentLibraryItem(from: $0) })
                let paginatedCounts = PaginatedCounts(from: json["meta"])
                return PaginatedResults(values: rootDirectory, counts: paginatedCounts)
            }
        })
    }

    /// Searches the entire content library for items matching the given term.
    ///
    /// - Parameter searchTerm: The search to perform
    /// - Returns: A `Paginated` collection of `ContentLibraryItem`
    ///            that can be fetched one page at a time as necessary.
    static func searchLibraryPaginated(_ searchTerm: String) -> Paginated<ContentLibraryItem> {
        return Paginated<ContentLibraryItem>(fetchValues: { (page) -> Promise<PaginatedResults<ContentLibraryItem>> in
            return firstly {
                let search = VillageCoreAPI.searchContentLibrary(term: searchTerm, page: page)
                return VillageService.shared.request(target: search)
            }.then { (json: JSON) -> PaginatedResults<ContentLibraryItem> in
                let rootDirectory = json["content"].arrayValue.compactMap({ ContentLibraryItem(from: $0) })
                let paginatedCounts = PaginatedCounts(from: json["meta"])
                return PaginatedResults(values: rootDirectory, counts: paginatedCounts)
            }
        })
    }

    /// Returns a `ContentLibrary` or directory for the given parent item.
    ///
    /// - Parameter item: The item to fetch the directory for.
    /// - Returns: `ContentLibraryServiceError.notDirectory` if the item is not
    ///            a directory, or a `Paginated` collection of `ContentLibraryItem`
    ///            that can be fetched one page at a time as necessary.
    static func getDirectoryPaginated(item: ContentLibraryItem) -> Paginated<ContentLibraryItem> {
        return Paginated<ContentLibraryItem>(fetchValues: { (page) -> Promise<PaginatedResults<ContentLibraryItem>> in
            return firstly {
                let directory = VillageCoreAPI.contentLibraryDirectory(contentId: item.id, page: page)
                return VillageService.shared.request(target: directory)
            }.then { (json: JSON) -> PaginatedResults<ContentLibraryItem> in
                let directory = json["content"].arrayValue.compactMap({ ContentLibraryItem(from: $0) })
                let paginatedCounts = PaginatedCounts(from: json["meta"])
                return PaginatedResults(values: directory, counts: paginatedCounts)
            }
        })
    }
    
    /// Creates a `URLRequest` for a non-directory content item (page, link, etc.)
    /// having set the appropriate cookie headers so that the user will be
    /// authenticated correctly to view the material.
    ///
    /// - Parameter item: The item to make the request for.
    /// - Returns: A `URLRequest` if successful.
    /// - Throws: `ContentLibraryServiceError.notContentItem` if the item isn't
    ///           a content type.
    public static func request(for item: ContentLibraryItem) throws -> URLRequest {
        guard !item.isDirectory else {
            throw ContentLibraryServiceError.notContentItem
        }
        
        guard let itemUrl = URL(string: Environment.current.appBaseURL.appendingPathComponent("content/1.0/@\(item.id))").absoluteString) else {
            throw ContentLibraryServiceError.invalidUrl
        }
        
        var request = URLRequest(url: itemUrl)
        let cookieHeaders = HTTPCookieStorage.shared.cookies.map({ HTTPCookie.requestHeaderFields(with: $0) }) ?? [:]
        let combinedHeaders = (request.allHTTPHeaderFields ?? [:])?.merging(cookieHeaders, uniquingKeysWith: {(_, new) in return new })
        request.allHTTPHeaderFields = combinedHeaders
        return request
    }
    
}

// MARK: - SwiftyJSON Extensions

internal extension ContentLibraryItem {
    
    init?(from response: JSON) {
        guard let id = response["id"].string else {
            return nil
        }
        
        self.init(
            id: id,
            parentId: response["parent"].string,
            name: response["name"].string ?? "Untitled",
            type: FileType(apiValue: response["type"].stringValue),
            hasChildren: response["hasChildren"].boolValue,
            created: villageCoreAPIDateFormatter.date(from: response["created"].stringValue),
            modified: villageCoreAPIDateFormatter.date(from: response["modified"].stringValue)
        )
    }
}
