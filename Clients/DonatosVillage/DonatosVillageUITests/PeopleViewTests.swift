import XCTest

class PeopleViewTests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
    }
}

extension Application {
	@discardableResult
	func openPeopleMenu() -> Application {
		openMenuBar().then { $0.staticTexts["main_menu_people_label"].tap() }
		return self
	}
}
