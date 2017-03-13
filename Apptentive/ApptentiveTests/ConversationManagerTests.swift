//
//  ConversationManagerTests.swift
//  Apptentive
//
//  Created by Frank Schmitt on 2/22/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

import XCTest

class ConversationManagerTests: XCTestCase {
	var conversationManager: ApptentiveConversationManager?
    
    override func setUp() {
        super.setUp()

		conversationManager = ApptentiveConversationManager(storagePath: <#T##String#>, operationQueue:  OperationQueue)
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
}
