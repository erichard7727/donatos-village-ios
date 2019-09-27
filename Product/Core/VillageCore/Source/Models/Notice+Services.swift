//
//  Notice+Services.swift
//  VillageCore
//
//  Created by Rob Feldmann on 3/26/19.
//  Copyright © 2019 Dynamit. All rights reserved.
//

import Foundation
import Promises
import SwiftyJSON

public extension Notification.Name {
    struct Notice {
        /// Posted whenever a notice is acknowledged.
        public static let WasAcknowledged = Notification.Name(rawValue: "com.dynamit.villageCore.notification.name.notice.wasAcknowledged")
    }
}

// MARK: - Notice Service

extension Notice {
    
    public func detailRequest() throws -> URLRequest {
        return try NoticeService.detailRequest(notice: self)
    }
    
    public func getAcknowledgedList() -> Promise<People> {
        return NoticeService.getAcknowledgedList(notice: self)
    }
    
    public func acknowledge() -> Promise<Notice> {
        return firstly {
            NoticeService.acknowledge(notice: self)
        }.then { notice in
            NotificationCenter.default.post(name: Notification.Name.Notice.WasAcknowledged, object: notice, userInfo: nil)
        }
    }

    public func rsvp(_ response: RSVPResponse) -> Promise<Notice> {
        guard response != .none else { return Promise(PromiseError.validationFailure) }

        let apiResponse: VillageCoreAPI.RSVPResponse = {
            switch response {
            case .no, .none:
                return .no
            case .maybe:
                return .maybe
            case .yes:
                return .yes
            }
        }()
        return NoticeService.rsvp(response: apiResponse, notice: self)
    }
    
}

public extension Sequence where Element == Notice {
    
    /// Extends typealias `Notices` to fetch all notices and news items.
    ///
    /// - Returns: A list of `Notices` (Notice and News types)
    static func allNoticesAndNewsPaginated() -> SectionedPaginated<Notice> {
        return NoticeService.getNoticesAndNewsPaginated()
    }

    /// Extends typealias `Notices` to search all notices and news items.
    ///
    /// - Returns: A list of `Notices` (Notice and News types)
    static func searchNoticesAndNewsPaginated(for term: String) -> SectionedPaginated<Notice> {
        return NoticeService.searchNoticesAndNewsPaginated(for: term)
    }
    
    /// Extends typealias `Notices` to fetch just notice items.
    ///
    /// - Returns: A list of `Notices` (only Notice types)
    static func allNoticesPaginated() -> SectionedPaginated<Notice> {
        return NoticeService.getNoticesPaginated()
    }

    /// Extends typealias `Notices` to search notice items.
    ///
    /// - Returns: A list of `Notices` matching the search term (only Notice types)
    static func searchNoticesPaginated(for term: String) -> SectionedPaginated<Notice> {
        return NoticeService.searchNoticesPaginated(for: term)
    }
    
    /// Extends typealias `Notices` to fetch just news items.
    ///
    /// - Returns: A list of `Notices` (only News types)
    static func allNewsPaginated() -> SectionedPaginated<Notice> {
        return NoticeService.getNewsPaginated()
    }

    /// Extends typealias `News` to search news items.
    ///
    /// - Returns: A list of `Notices` matching the search term (only News types)
    static func searchNewsPaginated(for term: String) -> SectionedPaginated<Notice> {
        return NoticeService.searchNewsPaginated(for: term)
    }
    
    /// Extends typealias `Notices` to fetch just event items.
    ///
    /// - Returns: A list of `Notices` (only Event types)
    static func allEventsPaginated() -> SectionedPaginated<Notice> {
        return NoticeService.getEventsPaginated()
    }

    /// Extends typealias `Notices` to search event items.
    ///
    /// - Returns: A list of `Notices` matching the search term (only Event types)
    static func searchEventsPaginated(for term: String) -> SectionedPaginated<Notice> {
        return NoticeService.searchEventsPaginated(for: term)
    }
    
}
