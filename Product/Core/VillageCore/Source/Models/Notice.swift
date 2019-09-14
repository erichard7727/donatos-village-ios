//
//  Notice.swift
//  VillageCore
//
//  Created by Rob Feldmann on 3/24/19.
//  Copyright © 2019 Dynamit. All rights reserved.
//

import Foundation

public typealias Notices = [Notice]

public struct Notice {
    
    public enum NoticeType {
        case news
        case notice
        case event
        
        init?(apiValue: String) {
            switch apiValue.lowercased() {
            case "news": self = .news
            case "notice": self = .notice
            case "event": self = .event
            default: return nil
            }
        }
    }

    public enum RSVPResponse {
        case no
        case maybe
        case yes
        case none

        init(apiValue: String) {
            switch apiValue.lowercased() {
            case "no": self = .no
            case "maybe": self = .maybe
            case "yes": self = .yes
            default: self = .none
            }
        }
    }
    
    public let id: String
    public let title: String
    public let body: String
    public let bodyContent: String
    public let type: NoticeType

    public let publishDate: Date
    public let isActive: Bool

    public let acknowledgeRequired: Bool
    public let isAcknowledged: Bool
    public let acceptedPercent: Float

    public let eventStartDateTime: Date?
    public let eventEndDateTime: Date?
    public var eventRsvpStatus: RSVPResponse

    public var eventRsvpDisplayStatus: String {
        switch (eventRsvpStatus, acknowledgeRequired) {
        case (.no, _):
            return "Not Going"
        case (.maybe, _):
            return "Interested"
        case (.yes, _):
            return "Going"
        case (.none, true):
            return "RSVP Needed"
        case (.none, false):
            return "No RSVP Needed"
        }
    }

    public let mediaAttachments: [MediaAttachment]
    public let person: Person
}

extension Notice: Hashable {
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public static func == (lhs: Notice, rhs: Notice) -> Bool {
        return lhs.id == rhs.id
    }
    
}
