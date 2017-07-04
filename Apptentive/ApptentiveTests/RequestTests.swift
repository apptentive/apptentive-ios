//
//  RequestTests.swift
//  Apptentive
//
//  Created by Frank Schmitt on 5/4/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

import XCTest

class RequestTests: XCTestCase {

	func testConversationRequest() {
		guard let conversation = ApptentiveConversation(state: .anonymous) else {
			XCTFail("unable to create conversation")
			return;
		}

		let request = ApptentiveConversationRequest(conversation: conversation)

		conversation.person.name = "Frank"
		conversation.person.emailAddress = "test@apptentive.com"

		do {
			if let JSONDictionary = try JSONSerialization.jsonObject(with: request.payload!, options: []) as? [String: Any], let appRelease = JSONDictionary["app_release"] as? [String: Any], let person = JSONDictionary["person"] as? [String: Any], let device = JSONDictionary["device"] as? [String: Any] {
				XCTAssertEqual(appRelease["type"] as? String, "ios")
				XCTAssertEqual(appRelease["cf_bundle_short_version_string"] as? String, conversation.appRelease.version.versionString)
				XCTAssertEqual(appRelease["cf_bundle_version"] as? String, conversation.appRelease.build.versionString)
				XCTAssertEqual((appRelease["app_store_receipt"] as? [String: Any])?["has_receipt"] as? Bool, conversation.appRelease.hasAppStoreReceipt)
				XCTAssertEqual(appRelease["debug"] as? Bool, conversation.appRelease.isDebugBuild)
				XCTAssertEqual(appRelease["overriding_styles"] as? Bool, conversation.appRelease.isOverridingStyles)

				XCTAssertEqual(appRelease["sdk_version"] as? String, kApptentiveVersionString)
				XCTAssertEqual(appRelease["sdk_programming_language"] as? String, "Objective-C")
				XCTAssertEqual(appRelease["sdk_author_name"] as? String, "Apptentive, Inc.")
				XCTAssertEqual(appRelease["sdk_platform"] as? String, "iOS")
				XCTAssertEqual(appRelease["sdk_distribution"] as? String, "source")
				XCTAssertEqual(appRelease["sdk_distribution_version"] as? String, kApptentiveVersionString)

				XCTAssertEqual(person["name"] as? String, conversation.person.name)
				XCTAssertEqual(person["email"] as? String, conversation.person.emailAddress)

				XCTAssertEqual(device["uuid"] as? String, conversation.device.uuid.uuidString)
					XCTAssertEqual(device["os_name"] as? String, conversation.device.osName)
				XCTAssertEqual(device["os_version"] as? String, conversation.device.osVersion.versionString)
				XCTAssertEqual(device["os_build"] as? String, conversation.device.osBuild)
				XCTAssertEqual(device["hardware"] as? String, conversation.device.hardware)
				XCTAssertEqual(device["carrier"] as? String, conversation.device.carrier)
				XCTAssertEqual(device["content_size_category"] as? String, conversation.device.contentSizeCategory)
				XCTAssertEqual(device["locale_raw"] as? String, conversation.device.localeRaw)
				XCTAssertEqual(device["locale_country_code"] as? String, conversation.device.localeCountryCode)
				XCTAssertEqual(device["locale_language_code"] as? String, conversation.device.localeLanguageCode)
				XCTAssertEqual(device["utc_offset"] as? Int, conversation.device.utcOffset)
			} else {
				XCTFail("can't decode JSON")
			}
		} catch {
			XCTFail("can't decode JSON")
		}
	}
}
