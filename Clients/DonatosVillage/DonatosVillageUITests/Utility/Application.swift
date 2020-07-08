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
		app/*@START_MENU_TOKEN@*/.buttons["settings_gear_button"]/*[[".buttons[\"settings\"]",".buttons[\"settings_gear_button\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
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