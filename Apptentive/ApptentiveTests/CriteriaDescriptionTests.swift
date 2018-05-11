//
//  CriteriaDescriptionTests.swift
//  ApptentiveTests
//
//  Created by Frank Schmitt on 2/21/18.
//  Copyright © 2018 Apptentive, Inc. All rights reserved.
//

import XCTest

class CriteriaDescriptionTests: XCTestCase {
	var conversation: ApptentiveConversation!

    override func setUp() {
		ApptentiveDevice.getPermanentDeviceValues()

		conversation = ApptentiveConversation(state: .anonymous)

		super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

	func testConversationFieldDescription() {
		XCTAssertEqual(conversation.descriptionForField(withPath: "current_time"), "current time")
	}

    func testEngagementFieldDescriptions() {
		XCTAssertEqual(conversation.descriptionForField(withPath: "interactions/foo/invokes/total"), "number of invokes for interaction 'foo'")
		XCTAssertEqual(conversation.descriptionForField(withPath: "interactions/foo/invokes/cf_bundle_short_version_string"), "number of invokes for interaction 'foo' for current version")
		XCTAssertEqual(conversation.descriptionForField(withPath: "interactions/foo/invokes/cf_bundle_version"), "number of invokes for interaction 'foo' for current build")
		XCTAssertEqual(conversation.descriptionForField(withPath: "interactions/foo/last_invoked_at/total"), "last time interaction 'foo' was invoked")

		XCTAssertEqual(conversation.descriptionForField(withPath: "code_point/foo/invokes/total"), "number of invokes for event 'foo'")
		XCTAssertEqual(conversation.descriptionForField(withPath: "code_point/foo/invokes/cf_bundle_short_version_string"), "number of invokes for event 'foo' for current version")
		XCTAssertEqual(conversation.descriptionForField(withPath: "code_point/foo/invokes/cf_bundle_version"), "number of invokes for event 'foo' for current build")
		XCTAssertEqual(conversation.descriptionForField(withPath: "code_point/foo/last_invoked_at/total"), "last time event 'foo' was invoked")
	}

	func testAppReleaseFieldDescriptions() {
		XCTAssertEqual(conversation.descriptionForField(withPath: "application/cf_bundle_short_version_string"), "app version (CFBundleShortVersionString)")
		XCTAssertEqual(conversation.descriptionForField(withPath: "application/cf_bundle_version"), "app build (CFBundleVersion)")
		XCTAssertEqual(conversation.descriptionForField(withPath: "time_at_install/total"), "time at install")
		XCTAssertEqual(conversation.descriptionForField(withPath: "time_at_install/cf_bundle_short_version_string"), "time at install for version")
		XCTAssertEqual(conversation.descriptionForField(withPath: "time_at_install/cf_bundle_version"), "time at install for build")
	}

	func testSDKFieldDescriptions() {
		XCTAssertEqual(conversation.descriptionForField(withPath: "sdk/version"), "SDK version")
		XCTAssertEqual(conversation.descriptionForField(withPath: "sdk/distribution"), "SDK distribution method")
		XCTAssertEqual(conversation.descriptionForField(withPath: "sdk/distribution_version"), "SDK distribution package version")
	}

	func testPersonFieldDescription() {
		XCTAssertEqual(conversation.descriptionForField(withPath: "person/name"), "person name")
		XCTAssertEqual(conversation.descriptionForField(withPath: "person/email"), "person email")
		XCTAssertEqual(conversation.descriptionForField(withPath: "person/custom_data/foo"), "person_data[foo]")
	}

	func testDeviceFieldDescription() {
		XCTAssertEqual(conversation.descriptionForField(withPath: "device/uuid"), "device identifier (identifierForVendor)")
		XCTAssertEqual(conversation.descriptionForField(withPath: "device/os_name"), "device OS name")
		XCTAssertEqual(conversation.descriptionForField(withPath: "device/os_version"), "device OS version")
		XCTAssertEqual(conversation.descriptionForField(withPath: "device/os_build"), "device OS build")
		XCTAssertEqual(conversation.descriptionForField(withPath: "device/hardware"), "device hardware")
		XCTAssertEqual(conversation.descriptionForField(withPath: "device/carrier"), "device carrier")
		XCTAssertEqual(conversation.descriptionForField(withPath: "device/content_size_category"), "device content size category")
		XCTAssertEqual(conversation.descriptionForField(withPath: "device/locale_raw"), "device raw locale")
		XCTAssertEqual(conversation.descriptionForField(withPath: "device/locale_country_code"), "device locale country code")
		XCTAssertEqual(conversation.descriptionForField(withPath: "device/locale_language_code"), "device locale language code")
		XCTAssertEqual(conversation.descriptionForField(withPath: "device/utc_offset"), "device UTC offset")
		XCTAssertEqual(conversation.descriptionForField(withPath: "device/integration_config"), "device integration configuration")
	}

	func testIndentPrinter() {
		let indentPrinter = ApptentiveIndentPrinter()

		XCTAssertEqual(indentPrinter.output, "")

		indentPrinter.append("foo")

		XCTAssertEqual(indentPrinter.output, "foo")

		indentPrinter.indent()
		indentPrinter.append("bar")

		XCTAssertEqual(indentPrinter.output, "foo\n  bar")

		indentPrinter.outdent()

		indentPrinter.append("foo2")

		XCTAssertEqual(indentPrinter.output, "foo\n  bar\nfoo2")
	}
}
