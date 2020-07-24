import XCTest

private func testSettingStatus(app: XCUIApplication, buttonTitle: String, expectedLabel: String, expectedImageIdentifier: String) {
	XCTAssert(app.navigationBars.staticTexts["Events"].exists)
	app.tables.cells.firstMatch.tap()
	
	let goingButton = app.buttons[buttonTitle]
	XCTAssert(goingButton.waitForExistence(timeout: 1.0))
	goingButton.tap()
	
	app.navigationBars.buttons.firstMatch.tap()
	
	XCTAssertEqual(expectedLabel, app.tables.cells.firstMatch.staticTexts.firstMatch.label)
	XCTAssertEqual(expectedImageIdentifier, app.tables.firstMatch.cells.firstMatch.images.firstMatch.identifier)
}

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
	
	func testSettingEventStatuses() throws {
		Application()
		.login(with: .AutomationStoreAssociation)
		.openEventsMenu()
		.then { app in
			testSettingStatus(app: app, buttonTitle: "Going", expectedLabel: "GOING", expectedImageIdentifier: "notice-needs-action")
			testSettingStatus(app: app, buttonTitle: "Interested", expectedLabel: "INTERESTED", expectedImageIdentifier: "notice-interested")
			testSettingStatus(app: app, buttonTitle: "Not Going", expectedLabel: "NOT GOING", expectedImageIdentifier: "notice-not-going")
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
