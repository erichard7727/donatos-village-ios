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
}

extension Application {
    @discardableResult
    func openEventsMenu() -> Application {
        openMenuBar().then { $0.staticTexts["main_menu_events_label"].tap() }
        return self
    }
}
