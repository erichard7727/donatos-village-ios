import XCTest

class DonatosVillageUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
    }
	
	func testLoginAndLogout() throws {
		Application()
			.login(with: .AutomationStoreAssociation)
			.logout()
    }
	
	func testOpeningMySchedule() throws {
		Application()
			.login(with: .AutomationStoreAssociation, behavior: .ignoreAndContinueIfAlreadyLoggedIn)
			.then { app in app.scrollViews.otherElements.buttons["My Schedule"].tap() }
	}
	
	func testViewingAllNoticesFromHomescreen() throws {
		Application()
			.login(with: .AutomationStoreAssociation, behavior: .ignoreAndContinueIfAlreadyLoggedIn)
			.then { app in
				app.scrollViews.containing(.other, identifier:"Vertical scroll bar, 4 pages").children(matching: .other).element(boundBy: 0).children(matching: .other).element(boundBy: 2)/*@START_MENU_TOKEN@*/.staticTexts["View All"]/*[[".buttons[\"View All\"].staticTexts[\"View All\"]",".staticTexts[\"View All\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
				app.tables/*@START_MENU_TOKEN@*/.staticTexts["New Holiday Pizzas"]/*[[".cells.staticTexts[\"New Holiday Pizzas\"]",".staticTexts[\"New Holiday Pizzas\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
				XCTAssertTrue(app.webViews.webViews.textViews/*@START_MENU_TOKEN@*/.staticTexts["Checking to see that the ™, the © and the ® all work in a notice."]/*[[".otherElements[\"Content Library Page Preview\"]",".otherElements[\"main\"].staticTexts[\"Checking to see that the ™, the © and the ® all work in a notice.\"]",".staticTexts[\"Checking to see that the ™, the © and the ® all work in a notice.\"]"],[[[-1,2],[-1,1],[-1,0,1]],[[-1,2],[-1,1]]],[0]]@END_MENU_TOKEN@*/.waitForExistence(timeout: 2.0))
		}
	}
	
	func testMenuBar() throws {
		Application()
			.login(with: .AutomationStoreAssociation, behavior: .ignoreAndContinueIfAlreadyLoggedIn)
			.openMenuBar()
			.then {
				let staticTexts = $0.scrollViews.otherElements.staticTexts
				XCTAssertTrue(staticTexts["Home"].waitForExistence(timeout: 2.0))
				XCTAssertTrue(staticTexts["Notices"].exists)
				XCTAssertTrue(staticTexts["Events"].exists)
				XCTAssertTrue(staticTexts["News"].exists)
				XCTAssertTrue(staticTexts["Chats"].exists)
				XCTAssertTrue(staticTexts["Promise in Actions"].exists)
				XCTAssertTrue(staticTexts["My Schedule"].exists)
				XCTAssertTrue(staticTexts["My Groups"].exists)
				XCTAssertTrue(staticTexts["Other Groups"].exists)
				XCTAssertTrue(staticTexts["People"].exists)
		}
	}

    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, *) {
            measure(metrics: [XCTOSSignpostMetric.applicationLaunch]) {
                XCUIApplication().launch()
            }
        }
    }
}
