//
//  Message.swift
//  VillageCore
//
//  Created by Allie Galuska on 4/17/19.
//  Copyright © 2019 Dynamit. All rights reserved.
//

import Foundation

public typealias Messages = [Message]

public struct Message {
    public let id: String
    
    public let author: Person
    public let authorId: String
    public let authorDisplayName: String

    public let streamId: String
    public let body: String
    public var isLiked: Bool
    public let likesCount: Int

    public let created: String
    public let updated: String
    public let isSystem: Bool
}
