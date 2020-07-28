//
//  LoginTests.swift
//  DonatosVillageUITests
//
//  Created by Nikola Angelkovik on 7/28/20.
//  Copyright © 2020 Donatos. All rights reserved.
//

import XCTest

class LoginTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }
    
    func testLoginAndLogout() throws {
        Application()
            .login(with: .automationStoreAssociation)
            .logout()
    }
}

