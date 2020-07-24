import XCTest

class DonatosVillageUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
    }
	
	func testLoginAndLogout() throws {
		Application()
			.login(with: .automationStoreAssociation)
			.logout()
    }
	
	func testOpeningMySchedule() throws {
		Application()
			.login(with: .automationStoreAssociation)
			.then { app in app.scrollViews.otherElements.buttons["My Schedule"].tap() }
	}
	
	func testViewingAllNoticesFromHomescreen() throws {
		Application()
			.login(with: .automationStoreAssociation)
			.then { app in
				app.scrollViews["scrollView"].otherElements.buttons["view_all_notices"].staticTexts["View All"].tap()
				app.tables/*@START_MENU_TOKEN@*/.staticTexts["New Holiday Pizzas"]/*[[".cells.staticTexts[\"New Holiday Pizzas\"]",".staticTexts[\"New Holiday Pizzas\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
				XCTAssertTrue(app.webViews.staticTexts["Checking to see that the ™, the © and the ® all work in a notice."].waitForExistence(timeout: 3.0))
		}
	}
	
	func testMenuBar() throws {
		Application()
			.login(with: .automationStoreAssociation)
			.openMenuBar()
			.then {
				let staticTexts = $0.scrollViews.otherElements.staticTexts
				XCTAssertTrue(staticTexts["Home"].waitForExistence(timeout: 2.0))
				XCTAssertTrue(staticTexts["main_menu_notices_label"].exists)
				XCTAssertTrue(staticTexts["main_menu_events_label"].exists)
				XCTAssertTrue(staticTexts["main_menu_news_label"].exists)
				XCTAssertTrue(staticTexts["main_menu_chats_label"].exists)
				XCTAssertTrue(staticTexts["main_menu_kudos_label"].exists)
				XCTAssertTrue(staticTexts["main_menu_schedule_label"].exists)
				XCTAssertTrue(staticTexts["main_menu_my_groups_label"].exists)
				XCTAssertTrue(staticTexts["main_menu_other_groups_label"].exists)
				XCTAssertTrue(staticTexts["main_menu_people_label"].exists)
		}
	}
    
    func testGoingBackToTheHomeScreenFromTheMenuBar() {
        Application()
            .login(with: .automationStoreAssociation)
            .openMenuBar()
            .then { app in
                let otherElements = app.scrollViews.otherElements
                otherElements.staticTexts["Home"].tap()
        }
    }
    
    func testOpeningNoticesFromTheMenuBar() throws {
        Application()
            .login(with: .automationStoreAssociation)
            .openMenuBar()
            .then { app in
                let otherElements = app.scrollViews.otherElements
                otherElements.staticTexts["main_menu_notices_label"].tap()
        }
    }
    
    func testOpeningEventsFromTheMenuBar() throws {
        Application()
            .login(with: .automationStoreAssociation)
            .openMenuBar()
            .then { app in
                let otherElements = app.scrollViews.otherElements
                otherElements.staticTexts["main_menu_events_label"].tap()
        }
    }
    
    func testOpeningNewsFromTheMenuBar() throws {
        Application()
            .login(with: .automationStoreAssociation)
            .openMenuBar()
            .then { app in
                let otherElements = app.scrollViews.otherElements
                otherElements.staticTexts["main_menu_news_label"].tap()
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
