import XCTest

class PeopleViewTests: DonatosUITests {
    
    var application: Application!

    override func setUpWithError() throws {
        application = Application()
        continueAfterFailure = false
    }
    
    override func tearDownWithError() throws {
        application = nil
    }

	func testOpeningPeopleMenuAndOpeningMainMenu() throws {
			application.login(with: .automationStoreAssociation)
			.openPeopleMenu()
			.then { app in
				app.navigationBars.buttons["menu_button"].tap()
				XCTAssert(app.staticTexts["main_menu_people_label"].exists)
			}
    }
	
	func testOpeningAddPersonView() throws {
		application.login(with: .automationStoreAssociation)
		.openPeopleMenu()
		.then { app in
			app.navigationBars.buttons.element(boundBy: 1).tap()
			XCTAssert(app.navigationBars.matching(identifier: "Add New User").count != 0)
		}
	}
	
	func testSearchingForUser() throws {
        application.login(with: .automationStoreAssociation)
		.openPeopleMenu()
		.searchTable(for: "Automation Two", waitForSearchToComplete: true)
		.then { app in
			app.tables.cells.firstMatch.tap()
			XCTAssert(app.navigationBars.matching(identifier: "Profile").firstMatch.waitForExistence(timeout: 3.0))
		}
	}
	
	func testOpeningChat() throws {
		application.login(with: .automationStoreAssociation)
		.openPeopleMenu()
		.searchTable(for: "Allie Galuska", waitForSearchToComplete: true)
		.then { app in
			app.tables.cells.firstMatch.tap()
			app.staticTexts["people_profile_new_chat"].tap()
			XCTAssert(app.navigationBars.matching(identifier: "Allie Galuska").firstMatch.waitForExistence(timeout: 3.0))
		}
	}
	
	func testCancellingSearch() throws {
		application.login(with: .automationStoreAssociation)
		.openPeopleMenu()
		.searchTable(for: "Allie Galuska", waitForSearchToComplete: true)
		.then { app in
			app.navigationBars.buttons.matching(NSPredicate(format: "label == %@", "Cancel")).firstMatch.tap()
			XCTAssert(app.tables.cells.count != 1)
		}
	}
}

extension Application {
	@discardableResult
	func openPeopleMenu() -> Application {
		openMenuBar().then { $0.staticTexts["main_menu_people_label"].tap() }
		return self
	}
}
