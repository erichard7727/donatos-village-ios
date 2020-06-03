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
        public static let streamKey = "directMessageConversationKey"

        /// Posted whenever a DM stream is on screen.
        ///
        /// Obtain the stream object in the `userInfo` dictionary by using
        /// the `streamKey`.
        ///
        /// Example:
        ///
        ///   `let stream = notification.userInfo?[Notification.Name.Stream.streamKey] as? VillageCore.Stream`
        public static let isViewingDirectMessageConversation = Notification.Name(rawValue: "com.dynamit.villagecore.notification.name.stream.isviewingdirectmessageconversation")

        /// Posted whenever a stream is subscribed to.
        ///
        /// Obtain the stream object in the `userInfo` dictionary by using
        /// the `streamKey`.
        ///
        /// Example:
        ///
        ///   `let stream = notification.userInfo?[Notification.Name.Stream.streamKey] as? VillageCore.Stream`
        public static let userDidSubscribe = Notification.Name(rawValue: "com.dynamit.villagecore.notification.name.stream.userDidSubscribe")

        /// Posted whenever a stream is unsubscribed from.
        ///
        /// Obtain the stream object in the `userInfo` dictionary by using
        /// the `streamKey`.
        ///
        /// Example:
        ///
        ///   `let stream = notification.userInfo?[Notification.Name.Stream.streamKey] as? VillageCore.Stream`
        public static let userDidUnsubscribe = Notification.Name(rawValue: "com.dynamit.villagecore.notification.name.stream.userDidUnsubscribe")
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
    
    public var hasDetails: Bool {
        return details != nil
    }
    
    public static func == (lhs: Stream, rhs: Stream) -> Bool {
        return lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
}
