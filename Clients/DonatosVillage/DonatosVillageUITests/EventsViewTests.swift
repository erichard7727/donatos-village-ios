import XCTest

class EventsViewTests: XCTestCase {
	override func setUpWithError() throws {
		continueAfterFailure = false
	}

	func testOpeningEvents() throws {
		Application()
		.login(with: .AutomationStoreAssociation)
		.openEventsMenu()
		.then { app in
			XCTAssert(app.navigationBars.staticTexts["Events"].exists)
		}
	}
	
	func testOpeningFirstEvent() throws {
		Application()
		.login(with: .AutomationStoreAssociation)
		.openEventsMenu()
		.then { app in
			XCTAssert(app.navigationBars.staticTexts["Events"].exists)
			app.tables.cells.firstMatch.tap()
			
			let buttons = app.buttons
			XCTAssert(buttons["Going"].waitForExistence(timeout: 1.0))
			XCTAssert(buttons["Interested"].waitForExistence(timeout: 1.0))
			XCTAssert(buttons["Not Going"].waitForExistence(timeout: 1.0))
		}
	}
}

extension Application {
    @discardableResult
    func openEventsMenu() -> Application {
        openMenuBar().then { $0.staticTexts["main_menu_events_label"].tap() }
        return self
    }
}
