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
    case streamDetails
    case sendMessage
    case subscribeToStream
}

struct StreamsService {
    
    struct Invite {
        public let streamId: String
        public let userIds: [Int]
    }
    
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
    
    //TODO: Ask harry styles about this thing
//    static func inviteUsersToStream(streamInvite: StreamInvite) -> Promise<StreamInvite> {
//        return firstly {
//            let invite = VillageCoreAPI.inviteUsersToStream(streamInvite: streamInvite)
//            return VillageService.shared.request(target: invite)
//        }.then { (json: JSON) -> StreamInvite in
//            let streamInvites = StreamInvite(from: json)
//            return streamInvites
//        }
//    }
    
    static func getStreamMembers(streamId: String) -> Promise<People> {
        return firstly {
            let members = VillageCoreAPI.streamMembers(streamId: streamId)
            return VillageService.shared.request(target: members)
        }.then { (json: JSON) -> People in
            let people = json["people"].arrayValue.compactMap({ Person(from: $0) })
            return people
        }
    }
    
    static func likeMessage(streamId: String, messageId: String) -> Promise<Void> {
        return VillageService.shared.request(target: VillageCoreAPI.setMessageLiked(isLiked: true, messageId: messageId, streamId: streamId)).asVoid()
    }
    
    static func dislikeMessage(streamId: String, messageId: String) -> Promise<Void> {
        return VillageService.shared.request(target: VillageCoreAPI.setMessageLiked(isLiked: false, messageId: messageId, streamId: streamId)).asVoid()
    }
    
    static func getOtherStreams(page: Int) -> Promise<Streams> {
        return firstly {
            let streams = VillageCoreAPI.otherStreams(page: page)
            return VillageService.shared.request(target: streams)
        }.then { (json: JSON) -> Streams in
            let groups = json["streams"].arrayValue.compactMap({ Stream(from: $0) })
            return groups
        }
    }
    
    static func getSubscriptions() -> Promise<Streams> {
        return firstly {
            let subscriptions = VillageCoreAPI.subscribedStreams
            return VillageService.shared.request(target: subscriptions)
        }.then { (json: JSON) -> Streams in
            let groups = json["streams"].arrayValue.compactMap({ Stream(from: $0) })
            return groups
        }
    }
    
    static func subscribeToStream(streamId: String) -> Promise<Stream> {
        return firstly {
            let streams = VillageCoreAPI.subscribeToStream(streamId: streamId)
            return VillageService.shared.request(target: streams)
        }.then { (json: JSON) -> Stream in
                let stream = try Stream(from: json).orThrow(StreamsServiceError.subscribeToStream)
                return stream
        }
    }
    
    static func getStreamDetails(streamId: String) -> Promise<Stream> {
        return firstly {
            let streams = VillageCoreAPI.streamDetails(streamId: streamId)
            return VillageService.shared.request(target: streams)
        }.then { (json: JSON) -> Stream in
            let stream = try Stream(from: json).orThrow(StreamsServiceError.streamDetails)
            return stream
        }
    }
    
    static func sendMessage(message: Message) -> Promise<Message> {
        return firstly  {
            let message = VillageCoreAPI.sendMessage(
                streamId: message.streamId,
                messageId: message.id,
                body: message.text ?? ""
            )
            return VillageService.shared.request(target: message)
        }.then { (json: JSON) -> Message in
            let message = try Message(from: json).orThrow(StreamsServiceError.sendMessage)
            return message
        }
    }
    
}

// MARK: - SwiftyJSON Extensions

internal extension Unread {
    
    init(from response: JSON) {
        self.init(
            streams: response["unreadCounts"].arrayValue.compactMap(Unread.StreamCount.init),
            notices: response["noticeUnreadCount"].intValue
        )
    }
}

internal extension Unread.StreamCount {
    
    init?(from response: JSON) {
        guard let streamId = response["streamId"].string else {
            return nil
        }
        
        self = Unread.StreamCount.init(
            id: streamId,
            count: response["unreadCount"].intValue
        )
    }
}

internal extension Stream {
    
    init?(from response: JSON) {
        guard
            let id = response["streamId"].string  ?? response["id"].string
        else {
            return nil
        }
        
        self = Stream.init(
            //TODO: Harry styles add stuff here
            deactivated: response["deactivated"].bool,
            description: response["description"].string,
            id: id,
            memberCount: response["memberCount"].int,
            messageCount: response["messageCount"].int,
            name: response["name"].string,
            ownerId: response["ownerId"].int,
            streamType: StreamType.init(apiValue: response["streamType"].string ?? "closed"),
            closedParties: response["closedParties"].arrayValue.compactMap({ Person(from: $0) })
        )
    }
    
}

internal extension Message {
    
    init?(from response: JSON) {
        guard let id = response["id"].string
        else {
                return nil
        }
        
        self = Message.init(
            id: id,
            person: Person(from: response["person"]),
            text: response["text"].stringValue,
            ownderDisplayName: response["ownerDisplayName"].stringValue,
            lastUpdated: response["lastUpdated"].stringValue,
            createdDate: response["createdDate"].stringValue,  
            streamId: response["streamid"].stringValue,
            likesCount: response["likesCount"].intValue,
            hasUserLikedMessage: response["hasUserLikedMessage"].boolValue,
            isSystem: response["isSystem"].boolValue
        )
    }
}
