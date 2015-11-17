//
//  CornerCasesThatShouldBeTrue.m
//  ApptentiveConnect
//
//  Created by Frank Schmitt on 11/16/15.
//  Copyright © 2015 Apptentive, Inc. All rights reserved.
//

#import "CriteriaTest.h"
#import "ATInteractionInvocation.h"

@interface CornerCasesThatShouldBeTrue : CriteriaTest

@end

@implementation CornerCasesThatShouldBeTrue

- (void)CornerCasesThatShouldBeTrue {
	XCTAssertTrue([self.interaction criteriaAreMet]);
}

@end
