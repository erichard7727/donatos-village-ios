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
}

extension Application {
	@discardableResult
	func openPeopleMenu() -> Application {
		openMenuBar().then { $0.staticTexts["main_menu_people_label"].tap() }
		return self
	}
}
