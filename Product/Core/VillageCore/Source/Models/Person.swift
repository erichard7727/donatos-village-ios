//
//  Person.swift
//  VillageCore
//
//  Created by Rob Feldmann on 3/13/19.
//  Copyright © 2019 Dynamit. All rights reserved.
//

import Foundation

public typealias People = [Person]

public struct Person {
    
    public let id: Int
    public var emailAddress: String

    public let displayName: String?
    public let avatarURL: URL?

    public var firstName: String?
    public var lastName: String?
    public var jobTitle: String?
    public var phone: String?
    public var twitter: String?

    public let deactivated: Bool

    public let kudos: (count: Int, points: Int)
    public var directories: [Int]
    
    public var acknowledgeDate: Date?
    

}

extension Person: Hashable {
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public static func == (lhs: Person, rhs: Person) -> Bool {
        return lhs.id == rhs.id
    }
    
}
