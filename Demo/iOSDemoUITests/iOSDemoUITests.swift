//
//  iOSDemoUITests.swift
//  iOSDemoUITests
//
//  Created by Frank Schmitt on 4/26/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

import XCTest

class iOSDemoUITests: XCTestCase {
    override func setUp() {
        super.setUp()

		let app = XCUIApplication()
		guard let APIKey = NSUserDefaults.standardUserDefaults().stringForKey("APIKey") else {
			XCTFail("API Key must be set as a launch argument to the test runner")
			return
		}

        // Put setup code here. This method is called before the invocation of each test method in the class.
		app.launchArguments = [ "-APIKey", APIKey, "-events", "<array><string>multichoice_survey</string><string>singlechoice_survey</string><string>singleline_survey</string></array>" ]
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        app.launch()

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
		let tabBarsQuery = app.tabBars

		while (!app.navigationBars["Interactions"].exists) {
			tabBarsQuery.buttons["Interactions"].tap()
		}

		let actionButton = app.navigationBars["Interactions"].buttons["Share"]
		let enabled = NSPredicate(format: "enabled == 1")
		expectationForPredicate(enabled, evaluatedWithObject: actionButton, handler: nil)
		waitForExpectationsWithTimeout(30, handler: nil)
    }

    func testSendingMessage() {
		let app = XCUIApplication()
		let tablesQuery = app.tables
		let tabBarsQuery = app.tabBars

		// Open Message Center
		tabBarsQuery.buttons["Messages"].tap()
		tablesQuery.staticTexts["Message Center"].tap()

		// Send a message
		tablesQuery.textViews[""].tap()
		app.typeText("Automated UI Test Message.")
		tablesQuery.buttons["Send"].tap()

		// Fill out and submit the Who Card
		tablesQuery.textFields["Name"].tap()
		app.typeText("Testy McTesterson")
		tablesQuery.textFields["Email"].tap()
		app.typeText("test@apptentive.com")
		tablesQuery.buttons["That's Me!"].tap()

		// Close message center
		app.navigationBars["Message Center"].buttons["Close"].tap()
    }

	func testSingleLineSurvey() {
		let app = XCUIApplication()
		let tabBarsQuery = app.tabBars

		while (!app.navigationBars["Events"].exists) {
			tabBarsQuery.buttons["Events"].tap()
		}

		app.tables.staticTexts["singleline_survey"].tap()
		let collectionViewsQuery = app.collectionViews
		let submitButton = collectionViewsQuery.buttons["Submit"]

		// Validation should fail with no responses
		submitButton.tap()
		XCTAssertTrue(app.toolbars.count == 1)

		let requiredSingleLineCell = collectionViewsQuery.childrenMatchingType(.Cell).elementBoundByIndex(1)
		let requiredSingleLineTextField = requiredSingleLineCell.textFields["Please provide a response"]
		requiredSingleLineTextField.tap()
		app.typeText("Test\n")

		let requiredMultilineCell = collectionViewsQuery.childrenMatchingType(.Cell).elementBoundByIndex(3)
		requiredMultilineCell.textViews["Please leave detailed feedback"].tap()
		app.typeText("\t \n")

		// Validation should fail with emtpy response
		XCTAssertTrue(app.toolbars.count == 1)

		app.typeText("Test\n")

		// Should validate properly once both text fields are filled
		XCTAssertTrue(app.toolbars.count == 0)

		submitButton.tap()
	}

	func testMulitselectSurvey() {
		let app = XCUIApplication()
		let tabBarsQuery = app.tabBars

		while (!app.navigationBars["Events"].exists) {
			tabBarsQuery.buttons["Events"].tap()
		}

		app.tables.staticTexts["multichoice_survey"].tap()
		let collectionViewsQuery = app.collectionViews

		collectionViewsQuery.cells["A"].tap()
		collectionViewsQuery.cells["B"].tap()
		collectionViewsQuery.cells["C"].tap()
		collectionViewsQuery.element.swipeUp()

		collectionViewsQuery.cells["D"].tap()
		collectionViewsQuery.cells["E"].tap()
		collectionViewsQuery.cells["F"].tap()

		let submitButton = collectionViewsQuery.buttons["Submit"]
		submitButton.tap()

		// Validation should fail (out of range and no required other text)
		XCTAssertTrue(app.toolbars.count == 1)

		collectionViewsQuery.cells["A"].tap()
		collectionViewsQuery.cells["D"].tap()

		// Validation should still fail (no required other text)
		XCTAssertTrue(app.toolbars.count == 1)

		collectionViewsQuery.cells["F"].textFields["Please specify"].tap()
		app.typeText(" ")

		// Whitespace doesn't count
		XCTAssertTrue(app.toolbars.count == 1)

		app.typeText("Test")

		// Should validate now
		XCTAssertTrue(app.toolbars.count == 0)

		submitButton.tap()
	}
}
