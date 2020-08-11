//
//  ChatsViewTests.swift
//  DonatosVillageUITests
//
//  Created by Sasho Jadrovski on 7/31/20.
//  Copyright © 2020 Donatos. All rights reserved.
//

import XCTest

class ChatsViewTests: DonatosUITests {
    
    var application: Application!

    override func setUpWithError() throws {
        application = Application()
        continueAfterFailure = false
    }
    
    override func tearDownWithError() throws {
        application = nil
    }
    
    func testOpeningChatsScreen() throws {
          
               application.login(with: .automationStoreAssociation)
               .openMenuBar()
               .then { app in
                   app.scrollViews.otherElements.staticTexts["main_menu_chats_label"].tap()
                   XCTAssert(app.navigationBars.matching(identifier: "Chats").count != 0, "Cannot reach Chats screen")
           }
       }
       
       func testIfThePlusButtonExists() throws {
           
               application.login(with: .automationStoreAssociation)
               .openMenuBar()
               .then { app in
                   app.scrollViews.otherElements.staticTexts["main_menu_chats_label"].tap()
                   XCTAssert(app.navigationBars.matching(identifier: "Chats").count != 0, "Cannot reach Chats screen")
                   XCTAssertTrue(app.navigationBars["Chats"].children(matching: .button).element(boundBy: 1).exists, "The Plus button should be present in the Chats controller")
           }
       }
       
       func testIfThePlusButtonIsHittable() throws {
     
               application.login(with: .automationStoreAssociation)
               .openMenuBar()
               .then { app in
                   app.scrollViews.otherElements.staticTexts["main_menu_chats_label"].tap()
                   XCTAssert(app.navigationBars.matching(identifier: "Chats").count != 0, "Cannot reach Chats screen")
                   XCTAssertTrue(app.navigationBars["Chats"].children(matching: .button).element(boundBy: 1).isHittable, "The Plus button should be hittable")
           }
       }
       
       func testIfThePlusButtonNavigatesToTheNewMessageScreen() throws {
          
               application.login(with: .automationStoreAssociation)
               .openMenuBar()
               .then { app in
                   app.scrollViews.otherElements.staticTexts["main_menu_chats_label"].tap()
                   XCTAssert(app.navigationBars.matching(identifier: "Chats").count != 0, "Cannot reach Chats screen")
                   app.navigationBars["Chats"].children(matching: .button).element(boundBy: 1).tap()
                   XCTAssert(app.navigationBars.matching(identifier: "New Message").count != 0, "Cannot reach New Message screen")
           }
       }
    
       func testIfTheBackButtonNavigatesBackToTheChatsScreen() throws {
          
               application.login(with: .automationStoreAssociation)
               .openMenuBar()
               .then { app in
                   app.scrollViews.otherElements.staticTexts["main_menu_chats_label"].tap()
                   XCTAssert(app.navigationBars.matching(identifier: "Chats").count != 0, "Cannot reach Chats screen")
                   app.navigationBars["Chats"].children(matching: .button).element(boundBy: 1).tap()
                   XCTAssert(app.navigationBars.matching(identifier: "New Message").count != 0, "Cannot reach New Message screen")
//                   app.navigationBars["New Message"].buttons["Chats"].tap()
           }
       }
}
