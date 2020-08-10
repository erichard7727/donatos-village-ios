//
//  NewsViewTests.swift
//  DonatosVillageUITests
//
//  Created by Carl Ritchie on 7/22/20.
//  Copyright © 2020 Donatos. All rights reserved.
//

import XCTest

class NewsViewTests: XCTestCase {
    
    var application: Application!
    let testNewsTitle = "congratulations"
    
    override func setUpWithError() throws {
        application = Application()
        continueAfterFailure = false
    }
    
    func testOpeningNews() throws {
        application.login(with: .automationStoreAssociation)
        .openNewsMenu()
        .then { app in
            XCTAssert(app.navigationBars.staticTexts["News"].exists)
            XCTAssert(app.navigationBars.matching(identifier: "News").count != 0, "Cannot reach News screen")
        }
    }
    
    func testOpenFirstEntryAndGoBack() throws {
        application.login(with: .automationStoreAssociation)
        .openNewsMenu()
        .then { app in
            app.tables.cells.firstMatch.tap()
            app.navigationBars.buttons["News"].tap()
            XCTAssert(app.navigationBars.staticTexts["News"].exists)
        }
    }
    
    func testOpeningNewsMenuAndOpeningMainMenu() throws {
        application.login(with: .automationStoreAssociation)
        .openNewsMenu()
        .then { app in
            app.navigationBars.buttons["menu_button"].tap()
            XCTAssert(app.staticTexts["main_menu_news_label"].exists)
        }
    }
    
    func testSearchForNews() throws {
        application.login(with: .automationStoreAssociation)
        .openNewsMenu()
        .searchTable(for: testNewsTitle, waitForSearchToComplete: true)
        .then { app in
            app.tables.cells.firstMatch.tap()
            XCTAssert(app.navigationBars.matching(identifier: "Congratulations Class of 2020").firstMatch.waitForExistence(timeout: 3.0))
        }
    }
    
    func testCancellingNewsSearch() throws {
        application.login(with: .automationStoreAssociation)
        .openNewsMenu()
        .searchTable(for: testNewsTitle, waitForSearchToComplete: true)
        .then { app in
            let cellsDuringSearch = app.tables.cells.count
            app.navigationBars.buttons.matching(NSPredicate(format: "label == %@", "Cancel")).firstMatch.tap()
            XCTAssertTrue(app.tables.cells.count != cellsDuringSearch)
        }
    }
}

extension Application {
    @discardableResult
    func openNewsMenu() -> Application {
        openMenuBar().then { $0.staticTexts["main_menu_news_label"].tap() }
        return self
    }
}
