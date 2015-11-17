//
//  CornerCasesThatShouldBeFalse.m
//  ApptentiveConnect
//
//  Created by Frank Schmitt on 11/16/15.
//  Copyright © 2015 Apptentive, Inc. All rights reserved.
//

#import "CriteriaTest.h"
#import "ATInteractionInvocation.h"

@interface CornerCasesThatShouldBeFalse : CriteriaTest

@end

@implementation CornerCasesThatShouldBeFalse

- (void)testCornerCasesThatShouldBeFalse {
	XCTAssertFalse([self.interaction criteriaAreMet]);
}

@end
