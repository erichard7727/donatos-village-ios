//
//  MenuTests.swift
//  DonatosVillageUITests
//
//  Created by Nikola Angelkovik on 7/28/20.
//  Copyright © 2020 Donatos. All rights reserved.
//

import XCTest

class MenuTests: XCTestCase {
    
    var application: Application!
    
    override func setUpWithError() throws {
        application = Application()
        continueAfterFailure = false
    }
    
    override func tearDownWithError() throws {
        application = nil
    }
    
    func testMenuBar() throws {
            application.login(with: .automationStoreAssociation)
            .openMenuBar()
            .then {
                let staticTexts = $0.scrollViews.otherElements.staticTexts
                XCTAssertTrue(staticTexts["Home"].waitForExistence(timeout: 2.0))
                XCTAssertTrue(staticTexts["main_menu_notices_label"].exists)
                XCTAssertTrue(staticTexts["main_menu_events_label"].exists)
                XCTAssertTrue(staticTexts["main_menu_news_label"].exists)
                XCTAssertTrue(staticTexts["main_menu_chats_label"].exists)
                XCTAssertTrue(staticTexts["main_menu_kudos_label"].exists)
                XCTAssertTrue(staticTexts["main_menu_schedule_label"].exists)
                XCTAssertTrue(staticTexts["main_menu_my_groups_label"].exists)
                XCTAssertTrue(staticTexts["main_menu_other_groups_label"].exists)
                XCTAssertTrue(staticTexts["main_menu_people_label"].exists)
        }
    }
    
    func testGoingBackToTheHomeScreenFromTheMenuBar() {
            application.login(with: .automationStoreAssociation)
            .openMenuBar()
            .then { app in
                let otherElements = app.scrollViews.otherElements
                otherElements.staticTexts["Home"].tap()
                XCTAssert(app.navigationBars.matching(identifier: "Home Stream").count != 0, "Cannot reach Home Stream screen")
        }
    }
    
    func testOpeningEventsFromTheMenuBar() throws {
            application.login(with: .automationStoreAssociation)
            .openMenuBar()
            .then { app in
                let otherElements = app.scrollViews.otherElements
                otherElements.staticTexts["main_menu_events_label"].tap()
                XCTAssert(app.navigationBars.matching(identifier: "Events").count != 0, "Cannot reach Events screen")
        }
    }
    
}
