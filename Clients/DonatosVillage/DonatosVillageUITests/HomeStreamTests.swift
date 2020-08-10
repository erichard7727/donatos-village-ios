import XCTest

class HomeStreamTests: XCTestCase {
    
    var application: Application!
    
    override func setUpWithError() throws {
        application = Application()
        continueAfterFailure = false
    }
    
    override func tearDownWithError() throws {
        application = nil
    }
    
    
    func testViewingAllNoticesFromHomescreen() throws {
        
       
            application.login(with: .automationStoreAssociation)
            .then { app in
                app.scrollViews["scrollView"].otherElements.buttons["view_all_notices"].staticTexts["View All"].tap()
                app.tables/*@START_MENU_TOKEN@*/.staticTexts["New Holiday Pizzas"]/*[[".cells.staticTexts[\"New Holiday Pizzas\"]",".staticTexts[\"New Holiday Pizzas\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
                XCTAssertTrue(app.webViews.staticTexts["Checking to see that the ™, the © and the ® all work in a notice."].waitForExistence(timeout: 20.0))
        }
        
        func testLaunchPerformance() throws {
            if #available(macOS 10.15, iOS 13.0, tvOS 13.0, *) {
                measure(metrics: [XCTOSSignpostMetric.applicationLaunch]) {
                    XCUIApplication().launch()
                }
            }
        }
    }
    
    func testOpeningMySchedule() throws {
            application.login(with: .automationStoreAssociation)
            .then { app in app.scrollViews.otherElements.buttons["My Schedule"].tap() }
    }
    
}
