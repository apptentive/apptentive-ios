//
//  TestUtils.swift
//  ApptentiveTests
//
//  Created by Alex Lementuev on 2/23/18.
//  Copyright © 2018 Apptentive, Inc. All rights reserved.
//

import Foundation

func contentsOfFile(atPath path: String) -> String? {
	do {
		return try String(contentsOfFile: path)
	} catch {
		return nil;
	}
}
