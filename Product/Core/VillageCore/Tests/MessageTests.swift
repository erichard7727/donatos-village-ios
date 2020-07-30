//
//  Messages.swift
//  VillageCoreTests
//
//  Created by Scott Harman on 7/28/20.
//  Copyright © 2020 Dynamit. All rights reserved.
//

import XCTest
@testable import VillageCore

class MessageTests: XCTestCase {
    
    var message: Message!
    

    override func setUpWithError() throws {
        
        
        let person = Person(id: 1, emailAddress: "testEmail", displayName: nil, avatarURL: nil, firstName: nil, lastName: nil, department: nil, jobTitle: nil, phone: nil, twitter: nil, deactivated: false, kudos: (count: 6, points: 6), directories: [0, 3], acknowledgeDate: nil)

        message = Message(id: "testId", author: person, authorId: 1, authorDisplayName: "testAuthor", streamId: "testStreamId", body: "testBody", isLiked: true, likesCount: 1, created: "testCreated", updated: "testUpdated", isSystem: true, attachment: nil)

        print(message.debugDescription)
    }

    override func tearDownWithError() throws {
//        message = nil
    }

    func testExample() throws {
       
//        XCTAssertNotNil(message)
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
