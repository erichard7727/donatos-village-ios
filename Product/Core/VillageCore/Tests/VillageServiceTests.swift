//
//  VillageServiceTests.swift
//  VillageCoreTests
//
//  Created by Rob Feldmann on 2/9/19.
//  Copyright © 2019 Dynamit. All rights reserved.
//

import XCTest
@testable import VillageCore

class VillageServiceTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testGetSecurityPolicies() {
        waitforAsync({ (expectation) in
            firstly {
                VillageService.shared.request(target: VillageCoreAPI.securityPolicies(userId: "20297"))
            }.then { json in
                XCTAssert(json["policies"].exists())
            }.catch { error in
                XCTAssert(false, error.localizedDescription)
            }.always {
                expectation.fulfill()
            }
        })
    }

}
