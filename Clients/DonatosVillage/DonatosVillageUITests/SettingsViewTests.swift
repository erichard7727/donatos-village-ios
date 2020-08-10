//
//  SettingsViewTests.swift
//  DonatosVillageUITests
//
//  Created by Nikola Angelkovik on 7/31/20.
//  Copyright © 2020 Donatos. All rights reserved.
//

import XCTest

class SettingsViewTests: XCTestCase {
    
    var application: Application!
    
    override func setUpWithError() throws {
        application = Application()
        continueAfterFailure = false
    }
    
    override func tearDownWithError() throws {
        application = nil
    }
    
    func testOpeningSettingsScreen() throws {
            application.login(with: .automationStoreAssociation)
            .openMenuBar()
            .then { app in
                app.otherElements["current_user_container"].tap()
                XCTAssert(app.navigationBars.matching(identifier: "Edit Settings").count != 0, "Cannot reach Edit Settings screen")
        }
    }
    
    func testIfTheSaveButtonExists() throws {
            application.login(with: .automationStoreAssociation)
            .openMenuBar()
            .then { app in
                app.otherElements["current_user_container"].tap()
                XCTAssert(app.navigationBars.matching(identifier: "Edit Settings").count != 0, "Cannot reach Edit Settings screen")
                XCTAssertTrue(app.navigationBars["Edit Settings"].buttons["Save"].exists, "The Save button should be present in the Edit Settings controller")
        }
    }
    
    func testIfTheSaveButtonIsHittable() throws {
            application.login(with: .automationStoreAssociation)
            .openMenuBar()
            .then { app in
                app.otherElements["current_user_container"].tap()
                XCTAssert(app.navigationBars.matching(identifier: "Edit Settings").count != 0, "Cannot reach Edit Settings screen")
                XCTAssertTrue(app.navigationBars["Edit Settings"].buttons["Save"].isHittable, "The Save button should be present in the Edit Settings controller")
        }
    }
    
    func testIfTheAlertAppearsWhenTheSaveButtonIsPressed() throws {
            application.login(with: .automationStoreAssociation)
            .openMenuBar()
            .then { app in
                app.otherElements["current_user_container"].tap()
                XCTAssert(app.navigationBars.matching(identifier: "Edit Settings").count != 0, "Cannot reach Edit Settings screen")
                app.navigationBars["Edit Settings"].buttons["Save"].tap()
                XCTAssertTrue(app.alerts["Success"].exists, "The alert should appear when the Save button is pressed")
        }
    }
    
    func testTheDismissingOfTheAlert() throws {
            application.login(with: .automationStoreAssociation)
            .openMenuBar()
            .then { app in
                app.otherElements["current_user_container"].tap()
                XCTAssert(app.navigationBars.matching(identifier: "Edit Settings").count != 0, "Cannot reach Edit Settings screen")
                app.navigationBars["Edit Settings"].buttons["Save"].tap()
                XCTAssertTrue(app.alerts["Success"].exists, "The alert should appear when the Save button is pressed")
                app.alerts["Success"].scrollViews.otherElements.buttons["Dismiss"].tap()
        }
    }
}
