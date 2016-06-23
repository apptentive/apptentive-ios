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
		app.launchArguments = [ "-APIKey", APIKey, "-events", "<array><string>launch_survey</string><string>other_survey</string></array>" ]
        
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

	func testSurveySingleLineText() {
		let app = XCUIApplication()
		let tabBarsQuery = app.tabBars

		while (!app.navigationBars["Events"].exists) {
			tabBarsQuery.buttons["Events"].tap()
		}

		app.tables.staticTexts["launch_survey"].tap()

		let collectionViewsQuery = app.collectionViews
		let optionalCell = collectionViewsQuery.childrenMatchingType(.Cell).elementBoundByIndex(0)
		let singleLineOptionalField = optionalCell.textFields["Please provide a response"]
		singleLineOptionalField.tap()
		optionalCell.textFields["Please provide a response"]
		app.typeText("Automated UI Text.")

		collectionViewsQuery.buttons["Submit"].tap()
		XCTAssertTrue(app.toolbars.count == 1)

		let requiredCell = collectionViewsQuery.childrenMatchingType(.Cell).elementBoundByIndex(1)
		let singleLineRequiredField = requiredCell.textFields["Please provide a response"]
		singleLineRequiredField.tap()
		singleLineRequiredField.tap()
		requiredCell.textFields["Please provide a response"]
		app.typeText("Automated UI Text.")

		XCTAssertTrue(app.toolbars.count == 0)

		collectionViewsQuery.buttons["Submit"].tap()
		XCTAssertFalse(app.navigationBars["Single-Line Text"].exists)
	}
}
