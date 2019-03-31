//
//  Unread+Services.swift
//  VillageCore
//
//  Created by Rob Feldmann on 3/31/19.
//  Copyright © 2019 Dynamit. All rights reserved.
//

import Foundation
import Promises

// MARK: - StreamsService

extension Unread {
    
    public static func getCounts() -> Promise<Unread> {
        return StreamsService.getUnreadCounts()
    }

}
