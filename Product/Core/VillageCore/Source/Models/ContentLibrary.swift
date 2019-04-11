//
//  ContentLibrary.swift
//  VillageCore
//
//  Created by Rob Feldmann on 3/31/19.
//  Copyright © 2019 Dynamit. All rights reserved.
//

import Foundation

/// A `ContentLibrary` is just an array of `ContentLibraryItem`s
public typealias ContentLibrary = [ContentLibraryItem]

public struct ContentLibraryItem {
    
    public enum FileType {
        case directory
        case contentPage
        case link
        case pdf
        case image
        case file

        init(apiValue: String) {
            switch apiValue {
            case "application/x-directory":
                self = .directory
            case "text/html":
                self = .contentPage
            case "application/x-href":
                self = .link
            case "application/pdf":
                self = .pdf
            case "image/png",
                 "image/jpeg":
                self = .image
            case "application/zip":
                fallthrough
            default:
                self = .file
            }
        }
    }
    
    public let id: String
    public let parentId: String?
    public let name: String
    public let type: FileType
    public let hasChildren: Bool
    
    public let created: Date?
    public let modified: Date?
    
}

public extension ContentLibraryItem {
    
    public var isDirectory: Bool {
        return type == .directory
    }
    
}
