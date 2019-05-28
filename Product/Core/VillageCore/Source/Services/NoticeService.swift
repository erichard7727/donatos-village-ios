//
//  NoticeService.swift
//  VillageCore
//
//  Created by Rob Feldmann on 3/25/19.
//  Copyright © 2019 Dynamit. All rights reserved.
//

import Foundation
import Promises
import SwiftyJSON

enum NoticeServiceError: Error {
    case unknown
    case invalidUrl
}

struct NoticeService {
    
    private init() { }
    
    static func getNoticesAndNews(page: Int = 1) -> Promise<Notices> {
        return self.getNotices(.all, page: page)
    }
    
    static func getNoticesAndNewsPaginated() -> Paginated<Notice> {
        return self.getNoticesPaginated(.all)
    }
    
    static func getNotices(page: Int = 1) -> Promise<Notices> {
        return self.getNotices(.notice, page: page)
    }
    
    static func getNoticesPaginated(page: Int = 1) -> Paginated<Notice> {
        return self.getNoticesPaginated(.notice)
    }
    
    static func getNews(page: Int = 1) -> Promise<Notices> {
        return self.getNotices(.news, page: page)
    }
    
    static func getNewsPaginated() -> Paginated<Notice> {
        return self.getNoticesPaginated(.news)
    }
    
    private static func getNotices(_ noticeType: VillageCoreAPI.NoticeType, page: Int = 1) -> Promise<Notices> {
        return firstly {
            let notices = VillageCoreAPI.notices(noticeType, page: page)
            return VillageService.shared.request(target: notices)
        }.then { (json: JSON) -> Notices in
            let notices = json["content"].arrayValue.compactMap({ Notice(from: $0) })
            return notices
        }
    }
    
    private static func getNoticesPaginated(_ noticeType: VillageCoreAPI.NoticeType) -> Paginated<Notice> {
        return Paginated<Notice>(fetchValues: { (page) -> Promise<PaginatedResults<Notice>> in
            return firstly {
                let notices = VillageCoreAPI.notices(noticeType, page: page)
                return VillageService.shared.request(target: notices)
            }.then { (json: JSON) -> PaginatedResults<Notice> in
                let notices = json["content"].arrayValue.compactMap({ Notice(from: $0) })
                let paginatedCounts = PaginatedCounts(from: json["meta"])
                return PaginatedResults(values: notices, counts: paginatedCounts)
            }
        })
    }
    
    public static func detailRequest(notice: Notice) throws -> URLRequest {
        guard let detailUrl = URL(string: "\(ClientConfiguration.current.appBaseURL)notice/1.0/\(notice.id)") else {
            throw NoticeServiceError.invalidUrl
        }
        
        var request = URLRequest(url: detailUrl)
        let cookieHeaders = HTTPCookieStorage.shared.cookies.map({ HTTPCookie.requestHeaderFields(with: $0) }) ?? [:]
        let combinedHeaders = (request.allHTTPHeaderFields ?? [:])?.merging(cookieHeaders, uniquingKeysWith: {(_, new) in return new })
        request.allHTTPHeaderFields = combinedHeaders
        return request
    }
    
    static func getAcknowledgedList(notice: Notice, page: Int = 1) -> Promise<People> {
        return firstly {
            let acknowledged = VillageCoreAPI.noticeAcknowledgedList(noticeId: notice.id, page: page)
            return VillageService.shared.request(target: acknowledged)
        }.then { (json: JSON) -> People in
            let people = json["people"].arrayValue.compactMap({ Person(from: $0) })
            return people
        }
    }
    
    static func acknowledge(notice: Notice) -> Promise<Notice> {
        return firstly {
            VillageService.shared.request(target: .acknowledgeNotice(noticeId: notice.id))
        }.then { _ in
            return notice
        }
    }
    
}

// MARK: - SwiftyJSON Extensions

internal extension Notice {
    
    init?(from response: JSON) {
        guard
            let id = response["id"].string,
            let title = response["title"].string,
            let body = response["body"].string,
            let type = NoticeType(apiValue: response["type"].stringValue),
            let publishDate = villageCoreAPIDateFormatter.date(from: response["publishDate"].stringValue),
            let person = Person.init(from: response["person"])
        else {
            return nil
        }
        
        self = Notice(
            id: id,
            title: title,
            body: body,
            type: type,
            publishDate: publishDate,
            isActive: response["active"].boolValue,
            acknowledgeRequired: response["acknowledgeRequired"].boolValue,
            isAcknowledged: response["acknowledged"].boolValue,
            acceptedPercent: response["acceptedPercent"].floatValue,
            mediaAttachments: response["mediaAttachment"].arrayValue.compactMap({ MediaAttachment(from: $0) }),
            person: person
        )
    }
    
}

internal extension MediaAttachment {
    
    init?(from response: JSON) {
        guard
            let id = response["id"].string,
            let url = response["url"].url,
            let type = response["type"].string,
            let name = response["name"].string,
            let ownerId = response["ownerId"].string
        else {
            return nil
        }
        
        self = MediaAttachment(
            id: id,
            url: url,
            type: type,
            name: name,
            isThumbnailImage: response["isThumbnailImage"].boolValue,
            ownerId: ownerId
        )
    }
    
}
