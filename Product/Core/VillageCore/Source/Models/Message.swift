//
//  Message.swift
//  VillageCore
//
//  Created by Allie Galuska on 4/17/19.
//  Copyright © 2019 Dynamit. All rights reserved.
//

import Foundation

/// An alias name that represents a list of messages
public typealias Messages = [Message]

///A discrete text communication sent to a recipient or a group of receipients.
public struct Message {
    
    // MARK: - Constant Stored Properties
    
    public let id: String
    public let author: Person
    public let authorId: Int
    public let authorDisplayName: String
    public let streamId: String
    public let body: String
    public var isLiked: Bool
    public var likesCount: Int
    public let created: String
    public let updated: String
    public let isSystem: Bool
    public let attachment: Attachment?
    
    // MARK: - Intialization
    
    /// Initialize a new Message instance
    /// - Parameters:
    ///   - id: The identifier of the message instance
    ///   - author: The person who created the message
    ///   - authorId: The unique identifier associated with the autor of the message
    ///   - authorDisplayName: The name visable to the people receiving the message
    ///   - streamId: The unique identifier associated with a particular stream
    ///   - body: The content of the message
    ///   - isLiked: An action that can be made by the recipients as a quick way to show approval of the messsage
    ///   - likesCount: The total of likes a message has received by all recipients
    ///   - created: The orignal date the message instance was created
    ///   - updated: The last date the message was updated by the author or recipients
    ///   - isSystem: An indicator of whether the message was created by the system rather than an author
    ///   - attachment: An optional media file that can be sent along with a message
    public init(
        id: String,
        author: Person,
        authorId: Int,
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
    
    /// A media file that is sent along with a message such as an image, meme or video
    struct Attachment: Equatable {
        
        // MARK: - Constants
        
        public let content: String
        public let type: String
        public let title: String
        public let width: Double
        public let height: Double
        public let url: URL
        
        // MARK: - Intialization
        
        /// Initialize a new Attachment instance
        /// - Parameters:
        ///   - content: The actual media file sent that represents the attachment instance
        ///   - type: The type of file sent with a message such an image, meme or video.
        ///   - title: The name that describes the attachment
        ///   - width: An attribute of a rendered media file that represents the measurment from side to side
        ///   - height: An attribute of a rendered media file that represents the measurment from top to bottom
        ///   - url: The internet address of the media file being attached to a message
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
