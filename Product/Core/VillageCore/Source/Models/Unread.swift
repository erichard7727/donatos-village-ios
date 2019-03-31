//
//  Unread.swift
//  VillageCore
//
//  Created by Rob Feldmann on 3/31/19.
//  Copyright © 2019 Dynamit. All rights reserved.
//

import Foundation

public struct Unread {
    
    public struct Stream {
        public let id: String
        public let count: Int
    }
    
    public let streams: [Stream]
    public let notices: Int
}
