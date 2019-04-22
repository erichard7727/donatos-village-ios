//
//  Stream.swift
//  VillageCore
//
//  Created by Rob Feldmann on 3/14/19.
//  Copyright © 2019 Dynamit. All rights reserved.
//

import Foundation

public typealias Streams = [Stream]

public struct Stream {
    
    public enum StreamType {
        case open
        case memberInvites
        case closed
        case global
    }
    
    public struct Details {
        // Available + Create
        public let streamType: StreamType
        public let description: String
        public let ownerId: String
        public let messageCount: Int
        public let memberCount: Int
        public let closedParties: People
        public let peopleIds: [String]
        public let deactivated: Bool

    }
    
    public let id: String
    public let name: String
    public var details: Details?
    
}
