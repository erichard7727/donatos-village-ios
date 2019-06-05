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
        case events
        
        init?(apiValue: String) {
            switch apiValue.lowercased() {
            case "news": self = .news
            case "notice": self = .notice
            case "events": self = .events
            default: return nil
            }
        }
    }
    
    public let id: String
    public let title: String
    public let body: String
    public let type: NoticeType

    public let publishDate: Date
    public let isActive: Bool

    public let acknowledgeRequired: Bool
    public let isAcknowledged: Bool
    public let acceptedPercent: Float

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
