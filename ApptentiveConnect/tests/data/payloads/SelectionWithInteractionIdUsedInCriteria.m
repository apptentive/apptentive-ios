//
//  SelectionWithInteractionIdUsedInCriteria.m
//  ApptentiveConnect
//
//  Created by Frank Schmitt on 11/16/15.
//  Copyright © 2015 Apptentive, Inc. All rights reserved.
//

#import "PayloadTest.h"

@interface SelectionWithInteractionIdUsedInCriteria : PayloadTest

@end

@implementation SelectionWithInteractionIdUsedInCriteria

- (void)testParsing {
	XCTAssertEqual(self.targets.count, 2);
	XCTAssertEqual(self.interactions.count, 2);
}

@end
