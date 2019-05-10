//
//  Stream.swift
//  VillageCore
//
//  Created by Rob Feldmann on 3/14/19.
//  Copyright © 2019 Dynamit. All rights reserved.
//

import Foundation

public extension Notification.Name {
    struct Stream {
        /// Posted whenever a DM stream is on screen.
        public static let directMessageConversationKey = "directMessageConversationKey"
        public static let IsViewingDirectMessageConversation = Notification.Name(rawValue: "com.dynamit.villagecore.notification.name.stream.isviewingdirectmessageconversation")
    }
}

public typealias Streams = [Stream]

public struct Stream: Hashable {

    public enum StreamType {
        case open
        case memberInvites
        case closed
        case global
    }
    
    public struct Details {
        
        // Available + Create
        public var streamType: StreamType?
        public let description: String
        public let ownerId: String
        public let messageCount: Int
        public let memberCount: Int
        public let closedParties: People
        public let peopleIds: [String]
        public let mostRecentMessage: Message?
        public let isRead: Bool
        public let unreadCount: Int
        public let lastMessageReadId: String?
        public let lastMessageText: String?
        public let lastMessageDate: String?
        public let deactivated: Bool

        public var isUnread: Bool {
            return !self.isRead
        }
    }
    
    public let id: String
    public let name: String
    public var details: Details?
    
    public static func == (lhs: Stream, rhs: Stream) -> Bool {
        return lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
}
