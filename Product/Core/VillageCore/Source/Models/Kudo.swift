//
//  Kudo.swift
//  VillageCore
//
//  Created by Rob Feldmann on 3/14/19.
//  Copyright © 2019 Dynamit. All rights reserved.
//

import Foundation

public typealias Kudos = [Kudo]

public struct Kudo  {
    
    public let id: Int
    public let achievementId: String
    public let achievementTitle: String
    public let comment: String
    public let points: Int
    public let receiver: Person
    public let sender: Person
    public let date: String
    
}
