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
    public var likesCount: Int

    public let created: String
    public let updated: String
    public let isSystem: Bool
    
    public let attachment: Attachment?
    
    public init(
        id: String,
        author: Person,
        authorId: String,
        authorDisplayName: String,
        streamId: String,
        body: String,
        isLiked: Bool,
        likesCount: Int,
        created: String,
        updated: String,
        isSystem: Bool,
        attachment: Message.Attachment?
        ) {
        self.id = id
        self.author = author
        self.authorId = authorId
        self.authorDisplayName = authorDisplayName
        self.streamId = streamId
        self.body = body
        self.isLiked = isLiked
        self.likesCount = likesCount
        self.created = created
        self.updated = updated
        self.isSystem = isSystem
        self.attachment = attachment
    }
}

public extension Message {
    struct Attachment {
        public let content: String
        public let type: String
        public let title: String
        public let width: Double
        public let height: Double
        public let url: URL
        
        public init(
            content: String,
            type: String,
            title: String,
            width: Double,
            height: Double,
            url: URL
        ) {
            self.content = content
            self.type = type
            self.title = title
            self.width = width
            self.height = height
            self.url = url
        }
    }
}
