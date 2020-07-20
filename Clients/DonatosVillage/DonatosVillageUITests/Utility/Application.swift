//
//  Application.swift
//  DonatosVillageUITests
//
//  Created by Grayson Hansard on 6/30/20.
//  Copyright © 2020 Donatos. All rights reserved.
//
import XCTest

public enum LoginBehavior {
	case logoutIfAlreadyLoggedIn
	case ignoreAndContinueIfAlreadyLoggedIn
	case throwErrorIfAlreadyLoggedIn
}

public final class Application {
	private let app: XCUIApplication = {
		let tmp = XCUIApplication()
		tmp.launchArguments.append(contentsOf: ["-PeppTalkIsUITesting", "YES"])
		return tmp
	}()
	
	public init() {
		app.launch()
	}
	
	public func login(with user: User, behavior: LoginBehavior = .ignoreAndContinueIfAlreadyLoggedIn) -> Application {
		let elementsQuery = app.scrollViews.otherElements
		let emailField = elementsQuery/*@START_MENU_TOKEN@*/.textFields["enter_email_field"]/*[[".textFields[\"Enter your Email\"]",".textFields[\"enter_email_field\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/
		
		var shouldDoLogin: Bool = emailField.exists
		if !emailField.exists {
			switch behavior {
			case .logoutIfAlreadyLoggedIn:
				logout()
				shouldDoLogin = true
			case .ignoreAndContinueIfAlreadyLoggedIn:
				shouldDoLogin = false
			case .throwErrorIfAlreadyLoggedIn:
				shouldDoLogin = true
			}
		}
		
		if shouldDoLogin {
			doLogin(emailField, user, elementsQuery)
		}

		return self
	}
	
	@discardableResult
	public func logout() -> Application {
		openMenuBar()
		app.staticTexts["user_settings_name"].tap()
		app.buttons["logout_button"].tap()
		return self
	}
	
	@discardableResult
	public func openMenuBar() -> Application {
		let navBar = app.navigationBars["Home Stream"]
		XCTAssertTrue(navBar.waitForExistence(timeout: 10.0))
		navBar.buttons["menu_button"].tap()
		return self
	}
	
	@discardableResult
	public func then(block:(XCUIApplication) -> Void ) -> Application {
		block(app)
		return self
	}
    
    @discardableResult
    public func searchTable(for text: String, waitForSearchToComplete: Bool = false) -> Application {
        then {
            let searchField = $0.searchFields.firstMatch
            searchField.tap()
            searchField.typeText(text)
            
            if (waitForSearchToComplete) {
                XCTAssert($0.tables.cells.firstMatch.waitForExistence(timeout: 10.0))
            }
        }
        return self
    }
	
	// MARK: - Private
	
	private func doLogin(_ emailField: XCUIElement, _ user: User, _ elementsQuery: XCUIElementQuery) {
		emailField.tap()
		emailField.typeText("\(user.email)\n")
		
		let passwordField = elementsQuery.secureTextFields["login_password_field"]
		XCTAssertTrue(passwordField.waitForExistence(timeout: 1.0))
		passwordField.tap()
		
		// Workaround for secure text field issue reporting that it doesn't have focus
		UIPasteboard.general.string = user.password
		app.menuItems["Paste"].tap()
		sleep(1)
		app.buttons["login_password_submit_button"].tap()
	}
}
