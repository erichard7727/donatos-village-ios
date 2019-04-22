//
//  Message+Services.swift
//  VillageCore
//
//  Created by Rob Feldmann on 4/21/19.
//  Copyright © 2019 Dynamit. All rights reserved.
//

import Foundation
import Promises

extension Message {
    
    public func getMessagesAfter(page: Int = 1) -> Promise<Messages> {
        return StreamsService.getMessages(after: self, page: page)
    }
    
    public func like() -> Promise<Message> {
        return StreamsService.like(message: self)
    }
    
    public func unlike() -> Promise<Message> {
        return StreamsService.dislike(message: self)
    }
    
}
