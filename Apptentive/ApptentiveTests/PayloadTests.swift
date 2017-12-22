//
//  PayloadTests.swift
//  Apptentive
//
//  Created by Frank Schmitt on 4/20/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

import XCTest

class PayloadTests: XCTestCase {
    
	func testEventPayload() {
		let payload = ApptentiveEventPayload(label: "event_1", creationDate: Date())!
		payload.interactionIdentifier = "abc123def456ghi789"
		payload.customData = ["string": "foo", "number": 2, "bool": true]

		let item1 = Apptentive.extendedData(itemID: "abc123", name: "ABC", category: "Whoseit", price: 5.99, quantity: 2, currency: "USD")
		let item2 = Apptentive.extendedData(itemID: "def456", name: "DEF", category: "Whatsit", price: 7.99, quantity: 1, currency: "CAD")

		payload.extendedData = [
			Apptentive.extendedData(date: Date()),
			Apptentive.extendedData(latitude: 49, longitude: -122),
			Apptentive.extendedData(transactionID: "ghi789", affiliation: "Affiliates, Inc.", revenue: 13.98, shipping: 2.99, tax: 1.48, currency: "USD", commerceItems: [item1, item2])
		]

		if let contents = self.testBoilerplateForPayload(payload, containerName: "event"), let customData = contents["custom_data"] as? [String:Any]  {
			XCTAssertEqual(contents["label"] as? String, "event_1")
			XCTAssertEqual(contents["interaction_id"] as? String, "abc123def456ghi789")

			XCTAssertEqual(customData["string"] as? String, "foo")
			XCTAssertEqual(customData["number"] as? Int, 2)
			XCTAssertEqual(customData["bool"] as? Bool, true)

			XCTAssertNotNil(contents["time"])
			XCTAssertNotNil(contents["commerce"])
			XCTAssertNotNil(contents["location"])
		} else {
			XCTFail()
		}
	}

	func testSurveyPayload() {
		let payload = ApptentiveSurveyResponsePayload(answers: ["56d49499c719925f3300000b":["id": "56d49499c719925f3300000b", "value": "Other Text"]], identifier: "56d49499c719925f3300000a", creationDate: Date())!

		if let contents = self.testBoilerplateForPayload(payload, containerName: "response"), let answers = contents["answers"] as? [String:Any], let answer = answers["56d49499c719925f3300000b"] as? [String:String] {
			XCTAssertEqual(contents["id"] as? String, "56d49499c719925f3300000a")
			XCTAssertEqual(answer["id"], "56d49499c719925f3300000b")
			XCTAssertEqual(answer["value"], "Other Text")
		} else {
			XCTFail()
		}
	}

	func testDevicePayload() {
		let payload = ApptentiveDevicePayload(deviceDiffs: ["custom_data": ["foo": true]])

		if let contents = self.testBoilerplateForPayload(payload, containerName: "device"), let customData = contents["custom_data"] as? [String:Any] {
			XCTAssertEqual(customData["foo"] as? Bool, true)
		} else {
			XCTFail()
		}
	}

	func testPersonPayload() {
		let payload = ApptentivePersonPayload(personDiffs: ["custom_data": ["foo": true], "name": "Frank"]);

		if let contents = self.testBoilerplateForPayload(payload, containerName: "person"), let customData = contents["custom_data"] as? [String:Any] {
			XCTAssertEqual(contents["name"] as? String, "Frank")
			XCTAssertEqual(customData["foo"] as? Bool, true)
		} else {
			XCTFail()
		}
	}

	func testLogoutPayload() {
		let payload = ApptentiveLogoutPayload()

		do {
			if let _ = try JSONSerialization.jsonObject(with: payload.payload!, options: []) as? [String: Any] {
			} else {
				XCTFail("can't decode JSON")
			}
		} catch {
			XCTFail("can't decode JSON")
		}
	}

	func testSDKAppReleasePayload() {
		let conversation = ApptentiveConversation(state: .anonymous)
		let payload = ApptentiveSDKAppReleasePayload(conversation: conversation)

		do {
			if let JSONDictionary = try JSONSerialization.jsonObject(with: payload.payload!, options: []) as? [String: Any], let appRelease = JSONDictionary["app_release"] as? [String: Any] {
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
			} else {
				XCTFail("can't decode JSON")
			}
		} catch {
			XCTFail("can't decode JSON")
		}
	}

// MARK: Helper functions
	
	func testBoilerplateForPayload(_ payload: ApptentivePayload, containerName: String) -> [String: Any]? {
		XCTAssertNotNil(payload.path);
		XCTAssertNotNil(payload.method);

		do {
			if let payloadData = payload.payload, let jsonDictionary = try JSONSerialization.jsonObject(with: payloadData, options: []) as? [String: Any] {
				XCTAssertEqual(jsonDictionary.count, 1)
				XCTAssertNotNil(jsonDictionary[containerName])

				if let contents = jsonDictionary[containerName] as? [String: Any] {
					XCTAssertNotNil(contents["nonce"])
					XCTAssertGreaterThan(contents["client_created_at"] as? Double ?? 0, 1492712408)
					XCTAssertEqual(contents["client_created_at_utc_offset"] as? Int, TimeZone.current.secondsFromGMT())

					return contents
				} else {
					XCTFail()

					return nil
				}
			}
		} catch {
			XCTFail("Invalid JSON data in payload")
		}

		return nil
	}
}
