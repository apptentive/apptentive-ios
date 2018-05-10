//
//  RetryPolicyTests.swift
//  ApptentiveTests
//
//  Created by Frank Schmitt on 4/2/18.
//  Copyright © 2018 Apptentive, Inc. All rights reserved.
//

import XCTest

class RetryPolicyTests: XCTestCase {
	let retryPolicy = ApptentiveRetryPolicy(initialBackoff: 1.0, base: 2.0);
    
    override func setUp() {
        super.setUp()

		// Need this to be predictable for testing
		retryPolicy.shouldAddJitter = false;

		retryPolicy.cap = 4;

		retryPolicy.retryStatusCodes = IndexSet(integer: 69);
    }

    func testBackoff() {
		XCTAssertEqual(retryPolicy.retryDelay, 1.0);

		retryPolicy.increaseRetryDelay();

		XCTAssertEqual(retryPolicy.retryDelay, 2.0);

		retryPolicy.increaseRetryDelay();

		XCTAssertEqual(retryPolicy.retryDelay, 4.0);

		retryPolicy.increaseRetryDelay();

		XCTAssertEqual(retryPolicy.retryDelay, 4.0);

		retryPolicy.resetRetryDelay();

		XCTAssertEqual(retryPolicy.retryDelay, 1.0);
    }

	func testShouldRetry() {
		XCTAssertFalse(retryPolicy.shouldRetryRequest(withStatusCode: 0));
		XCTAssertTrue(retryPolicy.shouldRetryRequest(withStatusCode: 69));
		XCTAssertFalse(retryPolicy.shouldRetryRequest(withStatusCode: 100));
	}
}
