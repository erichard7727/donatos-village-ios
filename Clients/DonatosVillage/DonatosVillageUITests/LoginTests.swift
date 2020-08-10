//
//  LoginTests.swift
//  DonatosVillageUITests
//
//  Created by Nikola Angelkovik on 7/28/20.
//  Copyright © 2020 Donatos. All rights reserved.
//

import XCTest

class LoginTests: XCTestCase {

    var application: Application!
    
    override func setUpWithError() throws {
        application = Application()
        continueAfterFailure = false
    }
    
    override func tearDownWithError() throws {
        application = nil
    }
    
    func testLoginAndLogout() throws {
        application.login(with: .automationStoreAssociation)
        .logout()
    }
}
