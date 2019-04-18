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
    public let deactivated: Bool?
    public let description: String?
    public let id: String
    public let memberCount: Int?
    public let messageCount: Int?
    public let name: String?
    public let ownerId: Int?
    public let streamType: StreamType?
    public let closedParties: People
    
    public enum StreamType {
        case open
        case openInvite
        case closed
        case global
        
        init?(apiValue: String) {
            switch apiValue.lowercased() {
            case "open": self = .open
            case "open_invite": self = .openInvite
            case "closed": self = .closed
            case "global": self = .global
            default: return nil
            }
        }
    }
}
