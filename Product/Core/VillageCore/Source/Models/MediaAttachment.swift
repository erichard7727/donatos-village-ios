//
//  MediaAttachment.swift
//  VillageCore
//
//  Created by Rob Feldmann on 3/25/19.
//  Copyright © 2019 Dynamit. All rights reserved.
//

import Foundation

public struct MediaAttachment {
    public let id: String
    public let url: URL
    public let type: String
    public let name: String
    public let isThumbnailImage: Bool
    public let ownerId: String
}
