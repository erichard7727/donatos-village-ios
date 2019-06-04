//
//  DirectMessageService.swift
//  VillageCore
//
//  Created by Rob Feldmann on 4/28/19.
//  Copyright © 2019 Dynamit. All rights reserved.
//

import Foundation
import Promises
import SwiftyJSON

enum DirectMessageServiceError: Error {
    case unknown
}

struct DirectMessageService {
    
    private init() { }
    
    static func directMessages() -> Promise<Streams> {
        return firstly {
            let dms = VillageCoreAPI.directMessageStreams
            return VillageService.shared.request(target: dms)
        }.then { (json: JSON) -> Streams in
            let streams = json["streams"].arrayValue.compactMap({ Stream(from: $0) })
            return streams
        }
    }
    
    static func invitePeople(_ people: People) -> Promise<Stream> {
        return firstly {
            let invite = VillageCoreAPI.inviteToDirectMessage(
                userIds: people.map({ String($0.id) })
            )
            return VillageService.shared.request(target: invite)
        }.then { (json: JSON) -> Stream in
            let dm = try Stream(from: json).orThrow(DirectMessageServiceError.unknown)
            return dm
        }
    }
    
}
