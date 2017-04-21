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
		let payload = ApptentiveEventPayload(label: "event_1")
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
		let payload = ApptentiveSurveyResponsePayload(answers: ["56d49499c719925f3300000b":["id": "56d49499c719925f3300000b", "value": "Other Text"]], identifier: "56d49499c719925f3300000a")

		if let contents = self.testBoilerplateForPayload(payload, containerName: "survey"), let answers = contents["answers"] as? [String:Any], let answer = answers["56d49499c719925f3300000b"] as? [String:String] {
			XCTAssertEqual(contents["id"] as? String, "56d49499c719925f3300000a")
			XCTAssertEqual(answer["id"], "56d49499c719925f3300000b")
			XCTAssertEqual(answer["value"], "Other Text")
		} else {
			XCTFail()
		}
	}

	func testMessagePayload() {
		let message = ApptentiveMessage(body: "Hello", attachments: [], senderIdentifier: "56d49499c719925f3300000b", automated: false, customData: ["string": "foo", "number": 2, "bool": true])
		let payload = ApptentiveMessagePayload(message: message)

		if let contents = self.testBoilerplateForPayload(payload, containerName: "message"), let customData = contents["custom_data"] as? [String:Any] {
			XCTAssertEqual(contents["body"] as? String, "Hello")
			XCTAssertFalse(contents["automated"] as? Bool ?? true)
			XCTAssertFalse(contents["hidden"] as? Bool ?? true)

			XCTAssertEqual(customData["string"] as? String, "foo")
			XCTAssertEqual(customData["number"] as? Int, 2)
			XCTAssertEqual(customData["bool"] as? Bool, true)
		}
	}

// MARK: Helper functions
	
	func testBoilerplateForPayload(_ payload: ApptentivePayload, containerName: String) -> [String: Any]? {
		XCTAssertEqual(payload.jsonDictionary.count, 1)
		XCTAssertNotNil(payload.jsonDictionary[containerName])
		XCTAssertNotNil(payload.path);
		XCTAssertNotNil(payload.httpMethod);

		if let contents = payload.jsonDictionary[containerName] as? [String: Any] {
			XCTAssertNotNil(contents["nonce"])
			XCTAssertGreaterThan(contents["client_created_at"] as? Double ?? 0, 1492712408)
			XCTAssertEqual(contents["client_created_at_utc_offset"] as? Int, TimeZone.current.secondsFromGMT())

			return contents
		} else {
			XCTFail()

			return nil
		}
	}

}
