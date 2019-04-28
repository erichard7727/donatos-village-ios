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
    case streamWithMissingDetails
}

fileprivate extension Stream.StreamType {
    
    var apiType: VillageCoreAPI.StreamType {
        switch self {
        case .open: return .open
        case .memberInvites: return .memberInvites
        case .closed: return .closed
        case .global: return .global
        }
    }
    
    init?(apiValue: String?) {
        switch apiValue?.lowercased() {
        case "open"?:
            self = .open
        case "open_invite"?:
            self = .memberInvites
        case "closed"?:
            self = .closed
        case "global"?:
            self = .global
        default:
            return nil
        }
    }
}

struct StreamsService {
    
    struct Invite {
        public let streamId: String
        public let userIds: [Int]
    }
    
    public struct MessageAttachment {
        let data: Data
        let mimeType: String
        
        fileprivate var apiMessageAttachment: VillageCoreAPI.MessageAttachment {
            return VillageCoreAPI.MessageAttachment(data: self.data, mimeType: self.mimeType)
        }
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
    
    static func getHomeStream(page: Int) -> Promise<Void> {
        #warning("TODO - Implement home stream")
        return Promise(Void())
    }
    
    static func subscribedStreams() -> Promise<Streams> {
        return firstly {
            let subscriptions = VillageCoreAPI.subscribedStreams
            return VillageService.shared.request(target: subscriptions)
        }.then { (json: JSON) -> Streams in
            let streams = json["streams"].arrayValue.compactMap({ Stream(from: $0) })
            return streams
        }
    }
    
    static func getOtherStreams(page: Int) -> Promise<Streams> {
        return firstly {
            let streams = VillageCoreAPI.otherStreams(page: page)
            return VillageService.shared.request(target: streams)
        }.then { (json: JSON) -> Streams in
            let streams = json["streams"].arrayValue.compactMap({ Stream(from: $0) })
            return streams
        }
    }
    
    static func searchOtherStreams(term: String, page: Int)-> Promise<Streams> {
        return firstly {
            let streams = VillageCoreAPI.searchOtherStreams(term: term, page: page)
            return VillageService.shared.request(target: streams)
        }.then { (json: JSON) -> Streams in
            let streams = json["streams"].arrayValue.compactMap({ Stream(from: $0) })
            return streams
        }
    }
    
    static func getDetails(of stream: Stream) -> Promise<Stream> {
        return firstly {
            let details = VillageCoreAPI.streamDetails(streamId: stream.id)
            return VillageService.shared.request(target: details)
        }.then { (json: JSON) -> Stream in
            let stream = try Stream(from: json).orThrow(StreamsServiceError.unknown)
            return stream
        }
    }
    
    static func getMembers(of stream: Stream) -> Promise<People> {
        return firstly {
            let members = VillageCoreAPI.streamMembers(streamId: stream.id)
            return VillageService.shared.request(target: members)
        }.then { (json: JSON) -> People in
            let people = json["people"].arrayValue.compactMap({ Person(from: $0) })
            return people
        }
    }
    
    static func getMessages(of stream: Stream, page: Int) -> Promise<Messages> {
        return firstly { () -> Promise<JSON> in
            let endpoint = VillageCoreAPI.streamMessages(streamId: stream.id, page: page)
            return VillageService.shared.request(target: endpoint)
        }.then { (json: JSON) -> Messages in
            let messages = json["messages"].arrayValue.compactMap({ Message(from: $0) })
            return messages
        }
    }
    
    static func getMessages(after message: Message, page: Int) -> Promise<Messages> {
        return firstly { () -> Promise<JSON> in
            let endpoint = VillageCoreAPI.streamMessagesStartingAfter(messageId: message.id, streamId: message.streamId, page: page)
            return VillageService.shared.request(target: endpoint)
        }.then { (json: JSON) -> Messages in
            let messages = json["messages"].arrayValue.compactMap({ Message(from: $0) })
            return messages
        }
    }
    
    static func editStream(_ stream: Stream, type: Stream.StreamType?, name: String?, description: String?) -> Promise<Stream> {
        guard let details = stream.details else {
            return Promise(StreamsServiceError.streamWithMissingDetails)
        }
        
        return firstly {
            let endpoint = VillageCoreAPI.createOrUpdateStream(
                streamId: stream.id,
                type: type?.apiType ?? details.streamType.apiType,
                name: name ?? stream.name,
                description: description ?? details.description,
                ownerId: details.ownerId
            )
            return VillageService.shared.request(target: endpoint)
        }.then { (json: JSON) -> Stream in
            let stream = try Stream(from: json).orThrow(StreamsServiceError.unknown)
            return stream
        }
    }
    
    static func createStream(type: Stream.StreamType, name: String, description: String, owner: Person) -> Promise<Stream> {
        return firstly {
            let endpoint = VillageCoreAPI.createOrUpdateStream(
                streamId: "stream-\(owner.id)-\(UUID().uuidString)",
                type: type.apiType,
                name: name,
                description: description,
                ownerId: String(owner.id)
            )
            return VillageService.shared.request(target: endpoint)
        }.then { (json: JSON) -> Stream in
            let stream = try Stream(from: json).orThrow(StreamsServiceError.unknown)
            return stream
        }
    }
    
    static func invitePeople(_ people: People, to stream: Stream) -> Promise<Void> {
        let invite = VillageCoreAPI.inviteToStream(
            streamId: stream.id,
            userIds: people.map({ String($0.id) })
        )
        return VillageService.shared.request(target: invite).asVoid()
    }
    
    static func subscribeTo(_ stream: Stream) -> Promise<Void> {
        let subscribe = VillageCoreAPI.setSubscribed(subscribed: true, streamId: stream.id)
        return VillageService.shared.request(target: subscribe).asVoid()
    }
    
    static func unsubscribeFrom(_ stream: Stream) -> Promise<Void> {
        let unsubscribe = VillageCoreAPI.setSubscribed(subscribed: false, streamId: stream.id)
        return VillageService.shared.request(target: unsubscribe).asVoid()
    }
    
    static func sendMessage(body: String, attachment: MessageAttachment?, from person: Person, to stream: Stream, progress progressBlock: ((Double) -> Void)?) -> Promise<Message> {
        return firstly  {
            let newMessage = VillageCoreAPI.sendMessage(
                streamId: stream.id,
                messageId: "message-\(person.id)-\(UUID().uuidString)",
                body: body,
                attachment: attachment?.apiMessageAttachment
            )
            return VillageService.shared.request(target: newMessage, progress: { (progressResponse) in
                progressBlock?(progressResponse.progress)
            })
        }.then { (json: JSON) -> Message in
            let message = try Message(from: json).orThrow(StreamsServiceError.unknown)
            return message
        }
    }
    
    static func like(message: Message) -> Promise<Message> {
        return firstly {
            let like = VillageCoreAPI.setMessageLiked(isLiked: true, messageId: message.id, streamId: message.streamId)
            return VillageService.shared.request(target: like).asVoid()
        }.then {
            var likedMessage = message
            likedMessage.isLiked = true
            likedMessage.likesCount = likedMessage.likesCount + 1
            return Promise(likedMessage)
        }
        
    }
    
    static func dislike(message: Message) -> Promise<Message> {
        return firstly {
            let dislike = VillageCoreAPI.setMessageLiked(isLiked: false, messageId: message.id, streamId: message.streamId)
            return VillageService.shared.request(target: dislike).asVoid()
        }.then {
            var dislikedMessage = message
            dislikedMessage.isLiked = false
            dislikedMessage.likesCount = max(0, dislikedMessage.likesCount - 1)
            return Promise(dislikedMessage)
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
        
        self = Unread.Stream(
            id: streamId,
            count: response["unreadCount"].intValue
        )
    }
}

internal extension Stream {
    
    init?(from response: JSON) {
        guard
            let id = response["id"].string,
            let name = response["name"].string
        else {
            return nil
        }
        
        self = Stream(
            id: id,
            name: name,
            details: Stream.Details(from: response)
        )
    }
    
}

internal extension Stream.Details {

    init?(from response: JSON) {
        let responseType = response["type"].string ?? response["streamType"].string
        guard
            let streamType = Stream.StreamType(apiValue: responseType),
            let ownerId = response["ownerId"].int
        else {
            return nil
        }
        
        self = Stream.Details(
            streamType: streamType,
            description: response["description"].stringValue,
            ownerId: String(ownerId),
            messageCount: response["messageCount"].intValue,
            memberCount: response["memberCount"].intValue,
            closedParties: response["closedParties"].arrayValue.compactMap({ Person(from: $0) }),
            peopleIds: response["peopleIds"].arrayValue.compactMap({ $0.string }),
            deactivated: response["deactivated"].boolValue
        )
    }

}

internal extension Message {
    
    init?(from response: JSON) {
        guard
            let id = response["id"].string,
            let author = Person(from: response["person"]),
            let authorId = response["ownerId"].string,
            let authorDisplayName = response["ownerDisplayName"].string,
            let streamId = response["streamId"].string
        else {
            return nil
        }
        
        self = Message.init(
            id: id,
            author: author,
            authorId: authorId,
            authorDisplayName: authorDisplayName,
            streamId: streamId,
            body: response["text"].stringValue,
            isLiked: response["hasUserLikedMessage"].boolValue,
            likesCount: response["likesCount"].intValue,
            created: response["createdDate"].stringValue,
            updated: response["lastUpdated"].stringValue,
            isSystem: response["isSystem"].boolValue,
            attachment: Attachment(from: response["attachment"])
        )
    }
    
}

internal extension Message.Attachment {
    init?(from response: JSON) {
        guard
            let content = response["content"].string,
            let type = response["type"].string,
            let url = response["url"].url
        else {
            return nil
        }
        
        self = Message.Attachment(
            content: content,
            type: type,
            title: response["title"].stringValue,
            width: response["dimension"]["width"].doubleValue,
            height: response["dimension"]["height"].doubleValue,
            url: url
        )
    }
}
