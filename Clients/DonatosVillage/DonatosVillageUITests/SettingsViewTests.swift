//
//  SettingsViewTests.swift
//  DonatosVillageUITests
//
//  Created by Nikola Angelkovik on 7/31/20.
//  Copyright © 2020 Donatos. All rights reserved.
//

import XCTest

class SettingsViewTests: XCTestCase {
    
    override func setUpWithError() throws {
        continueAfterFailure = false
    }
    
    func testOpeningSettingsScreen() throws {
        Application()
            .login(with: .automationStoreAssociation)
            .openMenuBar()
            .then { app in
                app.otherElements["current_user_container"].tap()
                XCTAssert(app.navigationBars.matching(identifier: "Edit Settings").count != 0, "Cannot reach Edit Settings screen")
        }
    }
    
    func testIfTheSaveButtonExists() throws {
        Application()
            .login(with: .automationStoreAssociation)
            .openMenuBar()
            .then { app in
                app.otherElements["current_user_container"].tap()
                XCTAssert(app.navigationBars.matching(identifier: "Edit Settings").count != 0, "Cannot reach Edit Settings screen")
                XCTAssertTrue(app.navigationBars["Edit Settings"].buttons["Save"].exists, "The Save button should be present in the Edit Settings controller")
        }
    }
}
