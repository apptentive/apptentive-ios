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
		app.launchArguments = [ "-APIKey", APIKey, "-events", "<array><string>multichoice_survey</string><string>singlechoice_survey</string><string>singleline_survey</string><string>strings_survey</string><string>nps_survey</string></array>" ]

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

	func testRangeSurvey() {
		let app = XCUIApplication()
		let tabBarsQuery = app.tabBars

		while (!app.navigationBars["Events"].exists) {
			tabBarsQuery.buttons["Events"].tap()
		}

		app.tables.staticTexts["nps_survey"].tap()
		let collectionViewsQuery = app.collectionViews

		XCTAssert(app.staticTexts["Not at all likely"].exists)
		XCTAssert(app.staticTexts["Extremely likely"].exists)

		let submitButton = collectionViewsQuery.buttons["Submit"]
		submitButton.tap()

		// Validation should fail (no range selected)
		XCTAssertTrue(app.toolbars.count == 1)

		collectionViewsQuery.cells["5"].tap()
		XCTAssert(collectionViewsQuery.cells["5"].selected)

		collectionViewsQuery.cells["6"].tap()

		// Validation should succeed
		XCTAssertTrue(app.toolbars.count == 0)

		XCTAssertFalse(collectionViewsQuery.cells["5"].selected)
		XCTAssert(collectionViewsQuery.cells["6"].selected)

		// Validation should succeed
		XCTAssertTrue(app.toolbars.count == 0)

		submitButton.tap()
	}


	func testStringsSurvey() {
		let app = XCUIApplication()
		let tabBarsQuery = app.tabBars

		while (!app.navigationBars["Events"].exists) {
			tabBarsQuery.buttons["Events"].tap()
		}

		app.tables.staticTexts["strings_survey"].tap()
		let collectionViewsQuery = app.collectionViews

		// Title
		XCTAssert(app.navigationBars["Vice lomo butcher"].exists)

		// Introduction
		XCTAssert(collectionViewsQuery.staticTexts["Kickstarter ethical tumblr direct trade, irony tote bag messenger bag."].exists)

		// Single-choice question
		XCTAssert(collectionViewsQuery.staticTexts["Truffaut try-hard disrupt migas narwhal fingerstache, gochujang affogato blue bottle jean shorts pour-over craft beer?"].exists)
		XCTAssert(collectionViewsQuery.cells["Twee pug bitters, portland polaroid artisan iPhone retro single-origin coffee."].exists)
		XCTAssert(collectionViewsQuery.cells["Kinfolk lomo hashtag migas stumptown before they sold out."].exists)

		collectionViewsQuery.element.swipeUp()

		// Multi-choice question
		XCTAssert(collectionViewsQuery.staticTexts["Dreamcatcher taxidermy PBR&B deep v. Art party ugh ethical wolf migas disrupt?"].exists)
		XCTAssert(collectionViewsQuery.cells["Trust fund skateboard 90's cronut 8-bit celiac fanny pack."].exists)
		XCTAssert(collectionViewsQuery.cells["Crucifix VHS organic beard, echo park shabby chic master cleanse hoodie sartorial raw denim yuccie disrupt mustache letterpress single-origin coffee."].exists)

		collectionViewsQuery.element.swipeUp()

		// Short answer
		XCTAssert(collectionViewsQuery.staticTexts["Heirloom cred sriracha readymade?"].exists)
		XCTAssert(collectionViewsQuery.textFields["Please provide a response"].exists)

		// Long answer
		XCTAssert(collectionViewsQuery.staticTexts["Mumblecore synth fashion axe scenester health goth, selvage sartorial paleo fanny pack farm-to-table offal church-key gentrify?"].exists)
		XCTAssert(collectionViewsQuery.textViews["Please leave detailed feedback"].exists)

		let submitButton = collectionViewsQuery.buttons["Submit"]
		submitButton.tap()
	}
}
