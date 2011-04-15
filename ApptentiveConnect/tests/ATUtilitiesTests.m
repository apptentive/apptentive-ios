//
//  ATUtilitiesTests.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 4/15/11.
//  Copyright 2011 Planetary Scale LLC. All rights reserved.
//

#import "ATUtilitiesTests.h"


@implementation ATUtilitiesTests
- (void)testEvenRect {
	CGRect testRect1 = CGRectMake(0.0, 0.0, 17.0, 21.0);
	CGRect result1 = ATCGRectOfEvenSize(testRect1);
	STAssertEquals(result1.size.width, (CGFloat)18.0, @"");
	STAssertEquals(result1.size.height, (CGFloat)22.0, @"");
	
	CGRect testRect2 = CGRectMake(0.0, 0.0, 18.0, 22.0);
	CGRect result2 = ATCGRectOfEvenSize(testRect2);
	STAssertEquals(result2.size.width, (CGFloat)18.0, @"");
	STAssertEquals(result2.size.height, (CGFloat)22.0, @"");
}
@end
