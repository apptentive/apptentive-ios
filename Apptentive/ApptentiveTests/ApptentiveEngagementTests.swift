//
//  ApptentiveEngagementTests.swift
//  ApptentiveTests
//
//  Created by Frank Schmitt on 11/5/18.
//  Copyright © 2018 Apptentive, Inc. All rights reserved.
//

import XCTest

class ApptentiveEngagementTests: XCTestCase {

	func testEventLabelsContainingCodePointSeparatorCharacters() {
		//Escape "%", "/", and "#".

		var i = "testEventLabelSeparators";
		var o = "testEventLabelSeparators";
		XCTAssertTrue(ApptentiveBackend.stringByEscapingCodePointSeparatorCharacters(in: i) == o, "Test escaping code point separator characters from event labels.");

		i = "test#Event#Label#Separators";
		o = "test%23Event%23Label%23Separators";
		XCTAssertTrue(ApptentiveBackend.stringByEscapingCodePointSeparatorCharacters(in: i) == o, "Test escaping code point separator characters from event labels.");

		i = "test/Event/Label/Separators";
		o = "test%2FEvent%2FLabel%2FSeparators";
		XCTAssertTrue(ApptentiveBackend.stringByEscapingCodePointSeparatorCharacters(in: i) == o, "Test escaping code point separator characters from event labels.");

		i = "test%Event/Label#Separators";
		o = "test%25Event%2FLabel%23Separators";
		XCTAssertTrue(ApptentiveBackend.stringByEscapingCodePointSeparatorCharacters(in: i) == o, "Test escaping code point separator characters from event labels.");

		i = "test#Event/Label%Separators";
		o = "test%23Event%2FLabel%25Separators";
		XCTAssertTrue(ApptentiveBackend.stringByEscapingCodePointSeparatorCharacters(in: i) == o, "Test escaping code point separator characters from event labels.");

		i = "test###Event///Label%%%Separators";
		o = "test%23%23%23Event%2F%2F%2FLabel%25%25%25Separators";
		XCTAssertTrue(ApptentiveBackend.stringByEscapingCodePointSeparatorCharacters(in: i) == o, "Test escaping code point separator characters from event labels.");

		i = "test#%///#%//%%/#Event_!@#$%^&*(){}Label1234567890[]`~Separators";
		o = "test%23%25%2F%2F%2F%23%25%2F%2F%25%25%2F%23Event_!@%23$%25^&*(){}Label1234567890[]`~Separators";
		XCTAssertTrue(ApptentiveBackend.stringByEscapingCodePointSeparatorCharacters(in: i) == o, "Test escaping code point separator characters from event labels.");

		i = "test%/#";
		o = "test%25%2F%23";
		XCTAssertTrue(ApptentiveBackend.stringByEscapingCodePointSeparatorCharacters(in: i) == o, "Test escaping code point separator characters from event labels.");
	}

	func testMergingCounts() {
		let aLongTimeAgo = Date(timeIntervalSinceNow: -1000)
		let aLittleWhileAgo = Date(timeIntervalSinceNow: -500)

		let oldCount = ApptentiveCount(totalCount: 5, versionCount: 10, buildCount: 20, lastInvoked: aLongTimeAgo);
		let newCount = ApptentiveCount(totalCount: 1, versionCount: 2, buildCount: 4, lastInvoked: aLittleWhileAgo);

		let mergedCount = ApptentiveCount.mergeOldCount(oldCount, withNewCount: newCount);

		XCTAssertEqual(mergedCount.totalCount, 6)
		XCTAssertEqual(mergedCount.versionCount, 2)
		XCTAssertEqual(mergedCount.buildCount, 4)
		XCTAssertEqual(mergedCount.lastInvoked, aLittleWhileAgo)

		let mergedCount2 = ApptentiveCount.mergeOldCount(nil, withNewCount: nil)

		XCTAssertEqual(mergedCount2.totalCount, 0)
		XCTAssertEqual(mergedCount2.versionCount, 0)
		XCTAssertEqual(mergedCount2.buildCount, 0)
		XCTAssertEqual(mergedCount2.lastInvoked, nil)

		let mergedCount3 = ApptentiveCount.mergeOldCount(oldCount, withNewCount: nil)

		XCTAssertEqual(mergedCount3.totalCount, 5)
		XCTAssertEqual(mergedCount3.versionCount, 0)
		XCTAssertEqual(mergedCount3.buildCount, 0)
		XCTAssertEqual(mergedCount3.lastInvoked, aLongTimeAgo)

		let mergedCount4 = ApptentiveCount.mergeOldCount(nil, withNewCount: newCount)

		XCTAssertEqual(mergedCount4.totalCount, 1)
		XCTAssertEqual(mergedCount4.versionCount, 2)
		XCTAssertEqual(mergedCount4.buildCount, 4)
		XCTAssertEqual(mergedCount4.lastInvoked, aLittleWhileAgo)
	}

	func testEscapedKeyForKey() {
		XCTAssertEqual(ApptentiveEngagement.escapedKey(forKey: "local#app#go/daddy"), "local#app#go%2Fdaddy")
		XCTAssertEqual(ApptentiveEngagement.escapedKey(forKey: "local#app#go#daddy"), "local#app#go%23daddy")
		XCTAssertEqual(ApptentiveEngagement.escapedKey(forKey: "local#app#go%25daddy"), nil)

		XCTAssertEqual(ApptentiveEngagement.escapedKey(forKey: "com.apptentive#app#launch"), nil)
	}

	func testMigration() {
		Bundle(for: ApptentiveEngagementTests.self).url(forResource: "conversation-4", withExtension:"archive")

		// Open a 4.0.0 archive with slash/pound/percent event names
		guard let fourOhUrl = Bundle(for: ApptentiveEngagementTests.self).url(forResource: "conversation-4", withExtension:"archive"), let fourOhConversation = NSKeyedUnarchiver.unarchiveObject(withFile: fourOhUrl.path) as? ApptentiveConversation else {
			XCTFail("Can't open 4.0 conversation archive")
			return
		}

		let fourOhEngagement = fourOhConversation.engagement
		XCTAssertEqual(fourOhEngagement.version, 2)
		XCTAssertEqual(fourOhEngagement.codePoints["local#app#go%2Fdaddy"]?.totalCount, 1)
		XCTAssertEqual(fourOhEngagement.codePoints["local#app#go%2Fdaddy"]?.buildCount, 1)
		XCTAssertEqual(fourOhEngagement.codePoints["local#app#go%2Fdaddy"]?.versionCount, 1)
		XCTAssertEqual(fourOhEngagement.codePoints["local#app#go%23daddy"]?.totalCount, 1)
		XCTAssertEqual(fourOhEngagement.codePoints["local#app#go%25daddy"]?.totalCount, 1)
		XCTAssertEqual(fourOhEngagement.codePoints["local#app#go%2520daddy"]?.totalCount, 1)


		// Open a 5.2.2 archive with slash/pound/percent event names
		guard let fiveTwoUrl = Bundle(for: ApptentiveEngagementTests.self).url(forResource: "conversation-5", withExtension:"archive"), let fiveTwoConversation = NSKeyedUnarchiver.unarchiveObject(withFile: fiveTwoUrl.path) as? ApptentiveConversation else {
			XCTFail("Can't open 5.2 conversation archive")
			return
		}

		let fiveTwoEngagement = fiveTwoConversation.engagement
		XCTAssertEqual(fiveTwoEngagement.version, 2)
		XCTAssertEqual(fiveTwoEngagement.codePoints["local#app#go%2Fdaddy"]?.totalCount, 2)
		XCTAssertEqual(fiveTwoEngagement.codePoints["local#app#go%2Fdaddy"]?.buildCount, 0)
		XCTAssertEqual(fiveTwoEngagement.codePoints["local#app#go%2Fdaddy"]?.versionCount, 0)
		XCTAssertEqual(fiveTwoEngagement.codePoints["local#app#go%23daddy"]?.totalCount, 2)
		// No longer migrating these, as there aren't any in the wild.
		// XCTAssertEqual(fiveTwoEngagement.codePoints["local#app#go%25daddy"]?.totalCount, 2)
		// XCTAssertEqual(fiveTwoEngagement.codePoints["local#app#go%2520daddy"]?.totalCount, 2)
	}
}
