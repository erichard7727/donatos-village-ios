import XCTest

class PeopleViewTests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
    }
	
	func testOpeningPeopleMenuAndOpeningMainMenu() throws {
		Application()
			.login(with: .AutomationStoreAssociation, behavior: .ignoreAndContinueIfAlreadyLoggedIn)
			.openPeopleMenu()
			.then { app in
				app.navigationBars.buttons["menu_button"].tap()
				XCTAssert(app.staticTexts["main_menu_people_label"].exists)
			}
    }
	
	func testOpeningAddPersonView() throws {
		Application()
		.login(with: .AutomationStoreAssociation, behavior: .ignoreAndContinueIfAlreadyLoggedIn)
		.openPeopleMenu()
		.then { app in
			app.navigationBars.buttons.element(boundBy: 1).tap()
			XCTAssert(app.navigationBars.matching(identifier: "Add New User").count != 0)
		}
	}
	
	func testSearchingForUser() throws {
		Application()
		.login(with: .AutomationStoreAssociation, behavior: .ignoreAndContinueIfAlreadyLoggedIn)
		.openPeopleMenu()
		.then { app in
			let searchField = app.searchFields.firstMatch
			searchField.tap()
			searchField.typeText("Automation Two")
			
			XCTAssert(app.tables.cells.firstMatch.waitForExistence(timeout: 10.0))
			
			app.tables.cells.firstMatch.tap()
			XCTAssert(			app.navigationBars.matching(identifier: "Profile").firstMatch.waitForExistence(timeout: 3.0))
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
