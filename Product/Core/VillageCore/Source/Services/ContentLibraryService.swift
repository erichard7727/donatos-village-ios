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
    
    static func getRootDirectory(page: Int = 1) -> Promise<ContentLibrary> {
        return firstly {
            let rootDirectory = VillageCoreAPI.contentLibraryRoot(page: page)
            return VillageService.shared.request(target: rootDirectory)
        }.then { (json: JSON) -> [ContentLibraryItem] in
            let rootDirectory = json["content"].arrayValue.compactMap({ ContentLibraryItem(from: $0) })
            return rootDirectory
        }
    }
    
    /// Returns a `ContentLibrary` or directory for the given parent item.
    ///
    /// - Parameter item: The item to fetch the directory for.
    /// - Returns: `ContentLibraryServiceError.notDirectory` if the item is not
    ///            a directory.
    static func getDirectory(item: ContentLibraryItem) -> Promise<ContentLibrary> {
        guard item.isDirectory else {
            return Promise(ContentLibraryServiceError.notDirectory)
        }
        
        return firstly {
            let directory = VillageCoreAPI.contentLibraryDirectory(contentId: item.id)
            return VillageService.shared.request(target: directory)
        }.then { (json: JSON) -> ContentLibrary in
            let directory = json["content"].arrayValue.compactMap({ ContentLibraryItem(from: $0) })
            return directory
        }
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
        
        guard let itemUrl = URL(string: "\(ClientConfiguration.current.appBaseURL)content/1.0/@\(item.id)") else {
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
