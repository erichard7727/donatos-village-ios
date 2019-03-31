//
//  StreamsService.swift
//  VillageCore
//
//  Created by Rob Feldmann on 3/31/19.
//  Copyright © 2019 Dynamit. All rights reserved.
//

import Foundation
import Promises
import SwiftyJSON

enum StreamsServiceError: Error {
    case unknown
}

struct StreamsService {
    
    private init() { }
    
    static func getUnreadCounts() -> Promise<Unread> {
        return firstly {
            let history = VillageCoreAPI.streamsHistory
            return VillageService.shared.request(target: history)
        }.then { (json: JSON) -> Unread in
            let unread = Unread(from: json)
            return unread
        }
    }
    
}

// MARK: - SwiftyJSON Extensions

internal extension Unread {
    
    init(from response: JSON) {
        self.init(
            streams: response["unreadCounts"].arrayValue.compactMap(Unread.Stream.init),
            notices: response["noticeUnreadCount"].intValue
        )
    }
}

internal extension Unread.Stream {
    
    init?(from response: JSON) {
        guard let streamId = response["streamId"].string else {
            return nil
        }
        
        self = Unread.Stream.init(
            id: streamId,
            count: response["unreadCount"].intValue
        )
    }
}
