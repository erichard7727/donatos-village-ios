//
//  Person.swift
//  VillageCore
//
//  Created by Rob Feldmann on 3/13/19.
//  Copyright © 2019 Dynamit. All rights reserved.
//

import Foundation

public typealias People = [Person]

public struct Person  {
    
    public let id: Int
    public let emailAddress: String

    public let displayName: String?
    public let avatarURL: URL?

    public let firstName: String?
    public let lastName: String?
    public let jobTitle: String?
    public let phone: String?
    public let twitter: String?

    public let deactivated: Bool

    public let kudos: (count: Int, points: Int)
    public let directories: [Int]

}
