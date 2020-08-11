//
//  LoginTests.swift
//  DonatosVillageUITests
//
//  Created by Nikola Angelkovik on 7/28/20.
//  Copyright © 2020 Donatos. All rights reserved.
//

import XCTest

class LoginTests: DonatosUITests {

    var application: Application!
    
    override func setUpWithError() throws {
        application = Application()
        continueAfterFailure = false
    }
    
    func testLoginAndLogout() throws {
        application.login(with: .automationStoreAssociation)
        .logout()
    }
}
