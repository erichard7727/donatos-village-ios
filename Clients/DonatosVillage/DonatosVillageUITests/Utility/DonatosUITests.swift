//
//  DonatosUITests.swift
//  DonatosVillageUITests
//
//  Created by Sean Conrad on 8/10/20.
//  Copyright © 2020 Donatos. All rights reserved.
//

import XCTest

class DonatosUITests: XCTestCase {
 
    override func recordFailure(withDescription description: String, inFile filePath: String, atLine lineNumber: Int, expected: Bool) {
            add(XCTAttachment(screenshot: XCUIScreen.main.screenshot()))
            super.recordFailure(withDescription: description, inFile: filePath, atLine: lineNumber, expected: expected)
    }

}
