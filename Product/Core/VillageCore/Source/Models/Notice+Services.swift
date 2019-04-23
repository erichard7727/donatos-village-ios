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
        /// Posted whenever User.current changes.
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
    
}

public extension Sequence where Element == Notice {
    
    /// Extends typealias `Notices` to fetch all notices and news items.
    ///
    /// - Parameter page: The page of results to fetch. Default == first.
    /// - Returns: A list of `Notices` (Notice and News types)
    static func allNoticesAndNews(page: Int = 1) -> Promise<Notices> {
        return NoticeService.getNoticesAndNews(page: page)
    }
    
    /// Extends typealias `Notices` to fetch just notice items.
    ///
    /// - Parameter page: The page of results to fetch. Default == first.
    /// - Returns: A list of `Notices` (only Notice types)
    static func allNotices(page: Int = 1) -> Promise<Notices> {
        return NoticeService.getNotices(page: page)
    }
    
    /// Extends typealias `Notices` to fetch just news items.
    ///
    /// - Parameter page: The page of results to fetch. Default == first.
    /// - Returns: A list of `Notices` (only News types)
    static func allNews(page: Int = 1) -> Promise<Notices> {
        return NoticeService.getNews(page: page)
    }
    
}
