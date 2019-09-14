//
//  HomeStream.swift
//  VillageCore
//
//  Created by Rob Feldmann on 5/2/19.
//  Copyright © 2019 Dynamit. All rights reserved.
//

import Foundation

#warning("JACK - Remove old HomeStream once DONV-345 is complete")
public struct HomeStream {
    
    public let streams: Streams
    public let notice: Notice?
    public var news: Notice?
    public var kudos: Kudos
        
}

public struct NewHomeStream {
    public let notice: Notice?
    public let events: Notices
    public var news: Notices
    public var kudos: Kudos
}
