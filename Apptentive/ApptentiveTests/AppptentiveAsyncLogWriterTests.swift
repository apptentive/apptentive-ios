//
//  AppptentiveAsyncLogWriterTests.swift
//  ApptentiveTests
//
//  Created by Alex Lementuev on 2/22/18.
//  Copyright © 2018 Apptentive, Inc. All rights reserved.
//

import XCTest

class AppptentiveAsyncLogWriterTests: XCTestCase {
	
	let destDir = (NSTemporaryDirectory() as NSString).appendingPathComponent("logs")
    
    override func setUp() {
        super.setUp()
		do {
			if FileManager.default.fileExists(atPath: destDir) {
				try FileManager.default.removeItem(atPath: destDir)
			}
		} catch {
			XCTFail("Unable to delete dir: \(destDir)")
		}
    }
    
    func testExample() {
		var writer: MockAsyncLogWriter!
		
		// create the first writer and output some Unicode text (Hiragana characters)
		writer = MockAsyncLogWriter(destDir: destDir, historySize: 3);
		writer.logMessage("あ");
		writer.logMessage("い");
		writer.logMessage("う");
		
		assertFiles(listLogFiles(destDir), ["あ\nい\nう\n"]);

		// create the second writer and output more text
		writer = MockAsyncLogWriter(destDir: destDir, historySize: 3);
		writer.logMessage("1");
		writer.logMessage("2");
		writer.logMessage("3");

		assertFiles(listLogFiles(destDir), ["あ\nい\nう\n", "1\n2\n3\n"]);

		// create the third writer and output more text
		writer = MockAsyncLogWriter(destDir: destDir, historySize: 3);
		writer.logMessage("4");
		writer.logMessage("5");
		writer.logMessage("6");

		assertFiles(listLogFiles(destDir), ["あ\nい\nう\n", "1\n2\n3\n", "4\n5\n6\n"]);

		// create the fourth writer and output more text
		writer = MockAsyncLogWriter(destDir: destDir, historySize: 3);
		writer.logMessage("7");
		writer.logMessage("8");
		writer.logMessage("9");

		// truncation should appear
		assertFiles(listLogFiles(destDir), ["1\n2\n3\n", "4\n5\n6\n", "7\n8\n9\n"]);

		// create the fifth writer and output more text
		writer = MockAsyncLogWriter(destDir: destDir, historySize: 3);
		writer.logMessage("10");
		writer.logMessage("11");
		writer.logMessage("12");

		// truncation should appear
		assertFiles(listLogFiles(destDir), ["4\n5\n6\n", "7\n8\n9\n", "10\n11\n12\n"]);

		// create the sixth writer and output more text
		writer = MockAsyncLogWriter(destDir: destDir, historySize: 3);
		writer.logMessage("13");
		writer.logMessage("14");
		writer.logMessage("15");

		// truncation should appear
		assertFiles(listLogFiles(destDir), ["7\n8\n9\n", "10\n11\n12\n", "13\n14\n15\n"]);
    }
	
	func assertFiles(_ files: [String], _ actual: [String]) {
		let expected = files.map() { contentsOfFile(atPath: $0)! }
		XCTAssertEqual(expected, actual)
	}
	
	func listLogFiles(_ destDir: String) -> [String] {
		do {
			let files = try FileManager.default.contentsOfDirectory(atPath: destDir)
			return files.sorted().map() {(destDir as NSString).appendingPathComponent($0)}
		} catch {
			XCTFail("Unable to read files from: \(destDir)")
		}
		return []
	}
	
	class MockAsyncLogWriter : ApptentiveAsyncLogWriter {
		static var nextId = 0
		
		override init(destDir: String, historySize: UInt) {
			super.init(destDir: destDir, historySize: historySize, queue: ApptentiveMockDispatchQueue())
		}
		
		override func createLogFilename() -> String {
			MockAsyncLogWriter.nextId += 1
			return "\(MockAsyncLogWriter.nextId)-\(super.createLogFilename())"
		}
	}
}
