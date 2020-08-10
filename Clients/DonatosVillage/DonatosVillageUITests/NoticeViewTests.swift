//
//  NoticeViewTests.swift
//  DonatosVillageUITests
//
//  Created by Thomas Goss on 7/17/20.
//  Copyright © 2020 Donatos. All rights reserved.
//

import XCTest

class NoticesViewTests: XCTestCase {
    
    var application: Application!
    let testNoticeTitle = "Test Notice 7-14-2020"
    
    override func setUpWithError() throws {
        application = Application()
        continueAfterFailure = false
    }
    
    func testOpeningNoticesMenuAndOpeningMainMenu() throws {
            application.login(with: .automationStoreAssociation)
            .openNoticesMenu()
            .then { app in
                app.navigationBars.buttons["menu_button"].tap()
                XCTAssert(app.staticTexts["main_menu_notices_label"].exists)
                XCTAssert(app.navigationBars.matching(identifier: "Notices").count != 0, "Cannot reach Notices screen")
        }
    }
    
    func testSearchingForNotice() throws {
            application.login(with: .automationStoreAssociation)
            .openNoticesMenu()
            .searchTable(for: testNoticeTitle, waitForSearchToComplete: true)
            .then { app in
                app.tables.cells.firstMatch.tap()
                XCTAssert(app.navigationBars.matching(identifier: testNoticeTitle).firstMatch.waitForExistence(timeout: 3.0))
        }
    }
    
    func testCancellingSearch() throws {
            application.login(with: .automationStoreAssociation)
            .openNoticesMenu()
            .searchTable(for: testNoticeTitle, waitForSearchToComplete: true)
            .then { app in
                let cellsDuringSearch = app.tables.cells.count
                app.navigationBars.buttons.matching(NSPredicate(format: "label == %@", "Cancel")).firstMatch.tap()
                XCTAssertTrue(app.tables.cells.count != cellsDuringSearch)
        }
    }
}

extension Application {
    @discardableResult
    func openNoticesMenu() -> Application {
        openMenuBar().then { $0.staticTexts["main_menu_notices_label"].tap() }
        return self
    }
}
