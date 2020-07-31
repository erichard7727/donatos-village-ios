//
//  ChatsViewTests.swift
//  DonatosVillageUITests
//
//  Created by Sasho Jadrovski on 7/31/20.
//  Copyright © 2020 Donatos. All rights reserved.
//

import XCTest

class ChatsViewTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }
    
    func testOpeningChatsScreen() throws {
           Application()
               .login(with: .automationStoreAssociation)
               .openMenuBar()
               .then { app in
                   app.scrollViews.otherElements.staticTexts["main_menu_chats_label"].tap()
                   XCTAssert(app.navigationBars.matching(identifier: "Chats").count != 0, "Cannot reach Chats screen")
           }
       }
       
       func testIfThePlusButtonExists() throws {
           Application()
               .login(with: .automationStoreAssociation)
               .openMenuBar()
               .then { app in
                   app.scrollViews.otherElements.staticTexts["main_menu_chats_label"].tap()
                   XCTAssert(app.navigationBars.matching(identifier: "Chats").count != 0, "Cannot reach Chats screen")
                   XCTAssertTrue(app.navigationBars["Chats"].children(matching: .button).element(boundBy: 1).exists, "The Plus button should be present in the Chats controller")
           }
       }
       
       func testIfThePlusButtonIsHittable() throws {
           Application()
               .login(with: .automationStoreAssociation)
               .openMenuBar()
               .then { app in
                   app.scrollViews.otherElements.staticTexts["main_menu_chats_label"].tap()
                   XCTAssert(app.navigationBars.matching(identifier: "Chats").count != 0, "Cannot reach Chats screen")
                   XCTAssertTrue(app.navigationBars["Chats"].children(matching: .button).element(boundBy: 1).isHittable, "The Plus button should be hittable")
           }
       }
       
       func testIfThePlusButtonNavigatesToTheNewMessageScreen() throws {
           Application()
               .login(with: .automationStoreAssociation)
               .openMenuBar()
               .then { app in
                   app.scrollViews.otherElements.staticTexts["main_menu_chats_label"].tap()
                   XCTAssert(app.navigationBars.matching(identifier: "Chats").count != 0, "Cannot reach Chats screen")
                   app.navigationBars["Chats"].children(matching: .button).element(boundBy: 1).tap()
                   XCTAssert(app.navigationBars.matching(identifier: "New Message").count != 0, "Cannot reach New Message screen")
           }
       }
    
       func testIfTheBackButtonNavigatesBackToTheChatsScreen() throws {
           Application()
               .login(with: .automationStoreAssociation)
               .openMenuBar()
               .then { app in
                   app.scrollViews.otherElements.staticTexts["main_menu_chats_label"].tap()
                   XCTAssert(app.navigationBars.matching(identifier: "Chats").count != 0, "Cannot reach Chats screen")
                   app.navigationBars["Chats"].children(matching: .button).element(boundBy: 1).tap()
                   XCTAssert(app.navigationBars.matching(identifier: "New Message").count != 0, "Cannot reach New Message screen")
                   app.navigationBars["New Message"].buttons["Chats"].tap()
           }
       }
}
