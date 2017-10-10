//
//  ApptentiveLogMonitor.m
//  Apptentive
//
//  Created by Alex Lementuev on 10/10/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveLogMonitor.h"

static NSString * const KeyAccessToken = @"accessToken";
static NSString * const KeyEmailRecipients = @"emailRecipients";
static NSString * const KeyLogLevel = @"logLevel";

@interface ApptentiveLogMonitorConfigration () <NSCoding>

@end

@implementation ApptentiveLogMonitorConfigration

- (instancetype)initWithAccessToken:(NSString *)accessToken {
	self = [super init];
	if (self) {
		_accessToken = accessToken;
		_emailRecipients = @[@"support@apptentive.com"];
		_logLevel = ApptentiveLogLevelVerbose;
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
	[coder encodeObject:_accessToken forKey:KeyAccessToken];
	[coder encodeObject:[_emailRecipients componentsJoinedByString:@","] forKey:KeyEmailRecipients];
	[coder encodeInt:(int)_logLevel forKey:KeyLogLevel];
}

- (nullable instancetype)initWithCoder:(NSCoder *)decoder {
	self = [super init];
	if (self) {
		_accessToken = [decoder decodeObjectForKey:KeyAccessToken];
		_emailRecipients = [[decoder decodeObjectForKey:KeyEmailRecipients] componentsSeparatedByString:@","];
		_logLevel = (ApptentiveLogLevel) [decoder decodeIntForKey:KeyLogLevel];
	}
	return self;
}

@end

@implementation ApptentiveLogMonitor

+ (BOOL)tryInitializeWithConfiguration:(ApptentiveLogMonitorConfigration *)configuration {
	return NO;
}

@end
