//
//  PayloadTest.m
//  ApptentiveConnect
//
//  Created by Frank Schmitt on 11/16/15.
//  Copyright © 2015 Apptentive, Inc. All rights reserved.
//

#import "PayloadTest.h"
#import "ATEngagementManifestParser.h"

@interface PayloadTest ()

@property (readonly, nonatomic) NSURL *JSONURL;

@end

@implementation PayloadTest

- (NSString *)JSONFilename {
	NSString *className = NSStringFromClass([self class]);

	if (![className hasPrefix:@"test"]) {
		return nil;
	} else {
		return [className substringFromIndex:4];
	}
}

- (void)setUp {
	[super setUp];

	NSURL *JSONURL= [[NSBundle bundleForClass:[self class]] URLForResource:self.JSONFilename withExtension:@"json"];
	NSData *JSONData = [NSData dataWithContentsOfURL:JSONURL];

	self.parser = [[ATEngagementManifestParser alloc] init];
	NSDictionary *targetsAndInteractions = [self.parser targetsAndInteractionsForEngagementManifest:JSONData];
	self.targets = targetsAndInteractions[@"targets"];
	self.interactions = targetsAndInteractions[@"interactions"];
}

@end
