//
//  Stream.swift
//  VillageCoreTests
//
//  Created by Scott Harman on 8/13/20.
//  Copyright © 2020 Dynamit. All rights reserved.
//

import XCTest
@testable import VillageCore

class StreamTests: XCTestCase {
    
    var stream: VillageCore.Stream!
    var peopleList: [Person]!
    var details: VillageCore.Stream.Details!
    
    override func setUpWithError() throws {
        peopleList = createTestPeopleList()
        details = createTestDetailsInstance()
        stream = createStreamInstance()
        XCTAssertNotNil(stream, "Stream should get instantiated and not be nil")
    }
    
    override func tearDownWithError() throws {
        details = nil
        peopleList = nil
        stream = nil
    }
    
    func testStreamDetailsPropertyIsNotNil() {
        
        // Given
        // When Stream is instantiated
        
        // Then
        XCTAssertNotNil(stream.details, "Stream details should be not be nil")
        
    }
    
    func testStreamDetailsPropertyIsNil() {
        
        // Given
        stream.details = nil
        
        // When Stream is instantiated
        
        // Then
        XCTAssertNil(stream.details, "Stream details should be nil")
        
    }
    
    func testStreamHasDetailsPropertyIsNotNil() {
        
        // Given
        // When Stream is instantiated
        
        // Then
        XCTAssertTrue(stream.hasDetails, "Stream hasDetails should be true")
        
    }
    
    func testStreamHasDetailsPropertyIsNil() {
        
        // Given
        stream.details = nil
        
        // When Stream is instantiated
        
        // Then
        XCTAssertFalse(stream.hasDetails, "Stream hasDetails should be false")
        
    }
    
    func testStreamIdShouldMatchTestId() {
        
        // Given
        let testId = "testID"
        
        // When Stream is instantiated
        
        // Then
        XCTAssertEqual(stream.id, testId, "Stream.id should match test id")
        
    }
    
    func testStreamNameShouldMatchTestName() {
        
        // Given
        let testName = "testName"
        
        // When Stream is instantiated
        
        // Then
        XCTAssertEqual(stream.name, testName, "Stream.name should match test name")
        
    }
    
    // MARK: - Private Methods
    
    private func createStreamInstance() -> VillageCore.Stream {
        
        VillageCore.Stream(details: details, id: "testID", name: "testName")
        
    }
    
    private func createTestDetailsInstance() -> VillageCore.Stream.Details {
        
        VillageCore.Stream.Details(
            streamType: .global,
            description: "testDescription",
            ownerId: "testOwnerID",
            messageCount: 2, memberCount: 4,
            closedParties: peopleList,
            peopleIds: ["1", "2"],
            mostRecentMessage: nil,
            isRead: true,
            unreadCount: 3,
            lastMessageReadId: "4",
            lastMessageText: "testLastMessageText",
            lastMessageDate: "testLastMessageDate",
            deactivated: false
        )
    }
    
    private func createTestPeopleList() -> [Person]{
        
        let personOne = Person(
            id: 1, emailAddress: "testEmail1",
            displayName: "testDisplayName1",
            avatarURL: nil,
            firstName: nil,
            lastName: nil,
            department: nil,
            jobTitle: nil,
            phone: nil,
            twitter: nil,
            deactivated: false,
            kudos: (count: 2, points: 4),
            directories: [4,7,8],
            acknowledgeDate: nil
        )
        
        let personTwo = Person(
            id: 2, emailAddress: "testEmail2",
            displayName: "testDisplayName2",
            avatarURL: nil,
            firstName: nil,
            lastName: nil,
            department: nil,
            jobTitle: nil,
            phone: nil,
            twitter: nil,
            deactivated: false,
            kudos: (count: 2, points: 4),
            directories: [7,1,9],
            acknowledgeDate: nil
        )
        
        return [personOne, personTwo]
    }
    
}
