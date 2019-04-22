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

extension Stream {
    
    public func getDetails() -> Promise<Stream> {
        return StreamsService.getDetails(of: self)
    }
    
    public func getMembers() -> Promise<People> {
        return StreamsService.getMembers(of: self)
    }
    
    public func getMessages(page: Int = 1) -> Promise<Messages> {
        return StreamsService.getMessages(of: self, page: page)
    }
    
    public static func new(type: StreamType, name: String, description: String, owner: Person) -> Promise<Stream> {
        return StreamsService.createStream(type: type, name: name, description: description, owner: owner)
    }
    
    public func invite(_ people: People) -> Promise<Void> {
        return StreamsService.invitePeople(people, to: self)
    }
    
    public func subscribe() -> Promise<Void> {
        return StreamsService.subscribeTo(self)
    }
    
    public func unsubscribe() -> Promise<Void> {
        return StreamsService.unsubscribeFrom(self)
    }
    
    public func send(message: String, from author: Person) -> Promise<Message> {
        return StreamsService.sendMessage(body: message, from: author, to: self)
    }

    
}

public extension Sequence where Element == Stream {
    
    /// Extends typealias `Streams` to fetch a list of subscribed streams.
    ///
    /// - Returns: A list of `Streams`
    public static func subscribed() -> Promise<Streams> {
        return StreamsService.subscribedStreams()
    }
    
    /// Extends typealias `Streams` to fetch a list of available streams
    /// that the user is not already subscribed to.
    ///
    /// - Parameter page: The page of results to fetch. Default == first.
    /// - Returns: A list of `Streams`
    public static func other(page: Int = 1) -> Promise<Streams> {
        return StreamsService.getOtherStreams(page: page)
    }
    
    /// Extends typealias `Streams` to search for a stream.
    ///
    /// - Parameters:
    ///   - term: The user's search term
    ///   - page: The page of results to fetch. Default == first.
    /// - Returns: A list of `Streams`
    public static func searchOthers(for term: String, page: Int = 1) -> Promise<Streams> {
        return StreamsService.searchOtherStreams(term: term, page: page)
    }
    
}

