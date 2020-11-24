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
    
    var person: Person!
    var attachment: Message.Attachment!
    var message: Message!
    
    override func setUpWithError() throws {
        
        person = createPerson()
        attachment = createMessageAttachment()
        message = createNewMessage()
        
    }
    
    override func tearDownWithError() throws {
        
        person = nil
        attachment = nil
        message = nil
        
    }
    
    func testMessageIsNotNil() {
        
        // Given
        // When Message is instantiated
        
        // Then
        XCTAssertNotNil(message)
        
    }
    
    func testMessageIdMatchesTestMessageIdString() {
        
        // Given
        let testMessageId = "testId"
        
        // When Message is instantiated
        
        // Then
        XCTAssertEqual(message.id, testMessageId, "Message id doesn't match testMessageId string")
        
    }
    
    func testMessageAuthorMatchesTestPersonInstance() {
        
        // Given
        let testAuthor = person
        
        // When Message is instantiated
        
        // Then
        XCTAssertEqual(message.author, testAuthor, "Message author doesn't match test author")
    }
    
    func testAuthorIdIsOne() {
        
        // Given
        let authorId = 1
        
        // When Message is instantiated
        
        // Then
        XCTAssertEqual(message.authorId, authorId, "AutorId should equal one")
    }
    
    func testAuthorDisplayNameMatchesTestAuthorDisplayNameString() {
        
        // Given
        let testAuthorDisplayName = "testDislapyName"
        
        // When Message is instantiated
        
        // Then
        XCTAssertEqual(
            message.authorDisplayName,
            testAuthorDisplayName,
            "Message authorDisplayName doesn't match testAuthorDisplayName string"
        )
        
    }
    
    func testMessageStreamIdMatchesTestStreamIdString() {
        
        // Given
        let testsreamID = "testStreamId"
        
        // When Message is instantiated
        
        // Then
        XCTAssertEqual(
            message.streamId,
            testsreamID,
            "Message StreamId doesn't match testsreamID string"
        )
        
    }
    
    func testMessageBodyMatchesTestBodyString() {
        
        // Given
        let testBody = "testBody"
        
        // When Message is instantiated
        
        // Then
        XCTAssertEqual(message.body, testBody, "Message body doesn't match testBody string")
        
    }
    
    func testMessageIsLikedIsTrue() {
        
        // Given
        let isLiked = true
        
        // When Message is instantiated
        
        // Then
        XCTAssertEqual(message.isLiked, isLiked, "Message isLiked should be true")
        
    }
    
    func testMessageLikesCountIsOne() {
        
        // Given
        let likesCount = 1
        
        // When Message is instantiated
        
        // Then
        XCTAssertEqual(message.likesCount, likesCount, "Message likes count should equal one")
        
    }
    
    func testMessageCreatedMatchesTestCreatedString() {
        
        // Given
        let testCreated = "testCreated"
        
        // When Message is instantiated
        
        // Then
        XCTAssertEqual(
            message.created,
            testCreated ,
            "Message created doesn't match testCreated string"
        )
        
    }
    
    func testMessageUpdatedMatchesTestUpdatedString() {
        
        // Given
        let testUpdated = "testUpdated"
        
        // When Message is instantiated
        
        // Then
        XCTAssertEqual(
            message.updated,
            testUpdated ,
            "Message updated doesn't match testUpdated string"
        )
        
    }
    
    func testMessageIsSystemIsTrue() {
        
        // Given
        let testIsSystem = true
        
        // When Message is instantiated
        
        // Then
        XCTAssertEqual(message.isSystem, testIsSystem , "Message isSystem should be true")
        
    }
    
    func testMessageAttachmentMatchesTestAttachmentInstance() {
        
        // Given
        let testAttachment = attachment
        
        // When Message is instantiated
        
        // Then
        XCTAssertEqual(
            message.attachment,
            testAttachment,
            "Message attachment does not match testAttachment instance"
        )
        
    }
    
    // MARK: = Private Methods
    
    private func createNewMessage() -> Message {
        
        Message(
            id: "testId",
            author: person,
            authorId: 1,
            authorDisplayName: "testDislapyName",
            streamId: "testStreamId",
            body: "testBody",
            isLiked: true,
            likesCount: 1,
            created: "testCreated",
            updated: "testUpdated",
            isSystem: true,
            attachment: createMessageAttachment()
        )
        
    }
    
    private func createPerson() -> Person {
        
        Person(
            id: 1,
            emailAddress: "testEmail",
            displayName: nil, avatarURL: nil,
            firstName: nil, lastName: nil,
            department: nil, jobTitle: nil,
            phone: nil,
            twitter: nil,
            deactivated: false,
            kudos: (count: 6, points: 6),
            directories: [0, 3],
            acknowledgeDate: nil
        )
        
    }
    
    private func createMessageAttachment() -> Message.Attachment {
        
        Message.Attachment(
            content: "testContent",
            type: "testType",
            title: "testTilte",
            width: 2.0,
            height: 3.0,
            url: URL(string: "example.com")!
        )
        
    }
    
}
