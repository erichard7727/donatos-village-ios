//
//  Stream+Services.swift
//  VillageCore
//
//  Created by Allie Galuska on 4/16/19.
//  Copyright © 2019 Dynamit. All rights reserved.
//

import Foundation
import Promises

// Mark: - StreamService

public extension HomeStream {
    
    static func fetch(page: Int = 1) -> Promise<HomeStream> {
        return StreamsService.getHomeStream(page: page)
    }
    
}

public extension Stream {
    
    static func getBy(_ streamId: String) -> Promise<Stream> {
        return StreamsService.getStream(from: streamId)
    }
    
    func getDetails() -> Promise<Stream> {
        return StreamsService.getDetails(of: self)
    }
    
    func getMembers() -> Promise<People> {
        return StreamsService.getMembers(of: self)
    }
    
    func getMessagesPaginated() -> Paginated<Message> {
        return StreamsService.getMessagesPaginated(of: self)
    }
    
    func getMessages(page: Int = 1) -> Promise<Messages> {
        return StreamsService.getMessages(of: self, page: page)
    }
    
    func edit(type: Stream.StreamType?, name: String?, description: String?) -> Promise<Stream> {
        return StreamsService.editStream(self, type: type, name: name, description: description)
    }
    
    static func new(type: StreamType, name: String, description: String, owner: Person) -> Promise<Stream> {
        return StreamsService.createStream(type: type, name: name, description: description, owner: owner)
    }
    
    func invite(_ people: People) -> Promise<Void> {
        return StreamsService.invitePeople(people, to: self)
    }
    
    func subscribe() -> Promise<Void> {
        return StreamsService.subscribeTo(self)
    }
    
    func unsubscribe() -> Promise<Void> {
        return StreamsService.unsubscribeFrom(self)
    }
    
    func send(message: String, attachment: (data: Data, mimeType: String)? = nil, from author: Person, progress progressBlock: ((Double) -> Void)? = nil) -> Promise<Message> {
        let attachment = attachment.map({ StreamsService.MessageAttachment(data: $0, mimeType: $1) })
        return StreamsService.sendMessage(body: message, attachment: attachment, from: author, to: self, progress: progressBlock)
    }

    static func startDirectMessage(with people: People) -> Promise<Stream> {
        return DirectMessageService.invitePeople(people)
    }
    
}

public extension Sequence where Element == Stream {
    
    /// Extends typealias `Streams` to fetch a list of subscribed streams.
    ///
    /// - Returns: A list of `Streams`
    static func subscribed() -> Promise<Streams> {
        return StreamsService.subscribedStreams()
    }
    
    /// Extends typealias `Streams` to fetch a list of available streams
    /// that the user is not already subscribed to.
    ///
    /// - Returns: A `Paginated` collection of `Streams` that can be fetched
    ///            one page at a time as necessary.
    static func otherPaginated() -> Paginated<Stream> {
        return StreamsService.getOtherStreamsPaginated()
    }
    
    /// Extends typealias `Streams` to search for a stream.
    ///
    /// - Parameters:
    ///   - term: The user's search term
    /// - Returns: A `Paginated` collection of `Streams` that can be fetched
    ///            one page at a time as necessary.
    static func searchOthersPaginated(for term: String) -> Paginated<Stream> {
        return StreamsService.searchOtherStreamsPaginated(term: term)
    }
    
    /// Extends typealias `Streams` to fetch a list of direct messages.
    ///
    /// - Returns: A list of `Streams`
    static func directMessages() -> Promise<Streams> {
        return DirectMessageService.directMessages()
    }

}

public extension Stream {
    
    func ensureHasDetails(then perform: @escaping (VillageCore.Stream) -> Void) {
        if self.hasDetails {
            perform(self)
        } else {
            firstly {
                self.getDetails()
            }.then { groupWithDetails in
                perform(groupWithDetails)
            }.catch { (error) in
                perform(self)
            }
        }
    }
    
}
