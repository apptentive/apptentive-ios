//
//  PredicateParsing.m
//  ApptentiveConnect
//
//  Created by Frank Schmitt on 11/16/15.
//  Copyright © 2015 Apptentive, Inc. All rights reserved.
//

#import "CriteriaTest.h"
#import "ATInteractionInvocation.h"

@interface PredicateParsing : CriteriaTest

@end

@implementation PredicateParsing

- (void)testPredicateParsing {
	XCTAssertNotNil([self.interaction valueForKey:@"criteriaPredicate"]);
}

@end
