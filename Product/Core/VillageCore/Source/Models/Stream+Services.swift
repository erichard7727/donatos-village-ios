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
    //    public static func inviteUsersToStream(streamInvite: StreamInvite) -> Promise<StreamInvite> {
    //        return StreamsService.inviteUsersToStream(streamInvite: streamInvite)
    //    }
    
    public static func getMembers(streamId: String) -> Promise<People> {
        return StreamsService.getStreamMembers(streamId: streamId)
    }
    
    public static func likeMessage(streamId: String, messageId: String) -> Promise<Void> {
        return StreamsService.likeMessage(streamId: streamId, messageId: messageId)
    }
    
    public static func dislikeMessage(streamId: String, messageId: String) -> Promise<Void> {
        return StreamsService.dislikeMessage(streamId: streamId, messageId: messageId)
    }
    
    public static func getOtherStreams(page: Int) -> Promise<Streams> {
        return StreamsService.getOtherStreams(page: page)
    }
    
    public static func getSubsciptions() -> Promise<Streams> {
        return StreamsService.getSubscriptions()
    }
    
    public static func subscribeToStream(streamId: String) -> Promise<Stream> {
        return StreamsService.subscribeToStream(streamId: streamId)
    }
    
    public static func getStreamDetails(streamId: String) -> Promise<Stream> {
        return StreamsService.getStreamDetails(streamId: streamId)
    }
    
    //TODO: Create / Update Stream
    
    
    
    //TODO: send message
    public static func sendMessage(message: Message) -> Promise<Message> {
        return StreamsService.sendMessage(message: message)
    }
    
    //TODO: get stream messages (with history)
    //TODO: get stream messages (without history)
}

public extension Sequence where Element == Stream {
    
    /// Extends typealias `Stream` to
}

