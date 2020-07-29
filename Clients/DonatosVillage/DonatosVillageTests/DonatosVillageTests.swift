//
//  DonatosVillageTests.swift
//  DonatosVillageTests
//
//  Created by Joao Eloy on 6/16/20.
//  Copyright © 2020 Donatos. All rights reserved.
//

import XCTest
@testable import VillageCore

class DonatosVillageTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() {
        XCTAssertTrue(true)
    }
    
    func testConnectionFailedServiceErrorUsesErrorMessage() {
        let error = CocoaError(.coderInvalidValue) // Random error that will have a localized description
        let serviceError = ServiceError.connectionFailed(error)
        XCTAssertTrue(serviceError.userDisplayableMessage != ServiceError.genericFailureMessage) // Test that the serviceError uses the error's description rather than the generic one
    }
    
    func testConnectionFailedServiceErrorIgnoresEmptyErrorMessage() {
        class EmptyError: LocalizedError {
            public var errorDescription: String? {
                return NSLocalizedString("", comment: "")
            }
        }
        let error = EmptyError() // An error with no localized description
        let serviceError = ServiceError.connectionFailed(error)
        XCTAssertTrue(serviceError.userDisplayableMessage == ServiceError.genericFailureMessage) // Test that the service error uses a generic error message rather than the empty one
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
