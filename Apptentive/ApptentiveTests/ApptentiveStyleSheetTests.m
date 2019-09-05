//
//  ApptentiveStyleSheetTests.m
//  Apptentive
//
//  Created by Frank Schmitt on 3/18/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import "Apptentive.h"
#import "ApptentiveStyleSheet.h"
#import <XCTest/XCTest.h>


@interface ApptentiveStyleSheetTests : XCTestCase

@property (strong, nonatomic) ApptentiveStyleSheet *styleSheet;

@end


@implementation ApptentiveStyleSheetTests

- (void)setUp {
	[super setUp];

	self.styleSheet = [[ApptentiveStyleSheet alloc] init];
}

- (void)testUIAppearanceDefaults {
	[UITableView appearance].separatorColor = [UIColor redColor];
	[UITableView appearanceWhenContainedIn:[ApptentiveNavigationController class], nil].backgroundColor = [UIColor greenColor];

	if (@available(iOS 13.0, *)) {
#ifdef __IPHONE_13_0
		XCTAssertEqualObjects([self.styleSheet colorForStyle:ApptentiveColorSeparator], [UIColor separatorColor]);
		XCTAssertEqualObjects([self.styleSheet colorForStyle:ApptentiveColorCollectionBackground], [UIColor systemGroupedBackgroundColor]);
#endif
	} else {
		XCTAssertEqualObjects([self.styleSheet colorForStyle:ApptentiveColorSeparator], [UIColor redColor]);
		XCTAssertEqualObjects([self.styleSheet colorForStyle:ApptentiveColorCollectionBackground], [UIColor greenColor]);
	}
}

- (void)testCustomFontOverride {
	UIFontDescriptor *uglyFontDescriptor = [UIFontDescriptor fontDescriptorWithName:@"Papyrus" size:17.0];
	UIFont *uglyFont = [UIFont fontWithDescriptor:uglyFontDescriptor size:0.0];

	XCTAssertNotEqualObjects([self.styleSheet fontForStyle:UIFontTextStyleBody], uglyFont);

	[self.styleSheet setFontDescriptor:uglyFontDescriptor forStyle:UIFontTextStyleBody];

	XCTAssertEqualObjects([self.styleSheet fontForStyle:UIFontTextStyleBody], uglyFont);
}

- (void)testCustomColorOverride {
	XCTAssertNotEqualObjects([self.styleSheet colorForStyle:ApptentiveColorFailure], [UIColor greenColor]);

	[self.styleSheet setColor:[UIColor greenColor] forStyle:ApptentiveColorFailure];

	XCTAssertEqualObjects([self.styleSheet colorForStyle:ApptentiveColorFailure], [UIColor greenColor]);
}

- (void)testMessageColors {
	self.styleSheet.backgroundColor = [UIColor blackColor];
	self.styleSheet.primaryColor = [UIColor whiteColor];

	UIColor *replyCellColor = [self.styleSheet colorForStyle:ApptentiveColorReplyBackground];
	CGFloat brightness;

	[replyCellColor getHue:NULL saturation:NULL brightness:&brightness alpha:NULL];

	XCTAssertEqualWithAccuracy(brightness, 0.0313, 0.05);
}

@end
