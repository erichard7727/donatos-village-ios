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
}

struct NoticeService {
    
    private init() { }
    
    static func getNoticesAndNews(page: Int = 1) -> Promise<Notices> {
        return self.getNotices(.all, page: page)
    }
    
    static func getNotices(page: Int = 1) -> Promise<Notices> {
        return self.getNotices(.notice, page: page)
    }
    
    static func getNews(page: Int = 1) -> Promise<Notices> {
        return self.getNotices(.news, page: page)
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
            let publishDate = response["publishDate"].string,
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
