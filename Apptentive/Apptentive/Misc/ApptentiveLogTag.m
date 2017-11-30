//
//  ApptentiveLogTag.m
//  Apptentive
//
//  Created by Alex Lementuev on 3/29/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveLogTag.h"

NS_ASSUME_NONNULL_BEGIN

static ApptentiveLogTag *_conversationTag;
static ApptentiveLogTag *_networkTag;
static ApptentiveLogTag *_payloadTag;
static ApptentiveLogTag *_utilityTag;
static ApptentiveLogTag *_storageTag;
static ApptentiveLogTag *_logMonitorTag;


@implementation ApptentiveLogTag


+ (void)initialize {
	if ([self class] == [ApptentiveLogTag class]) {
		_conversationTag = [ApptentiveLogTag logTagWithName:@"CONVERSATION" enabled:YES];
		_networkTag = [ApptentiveLogTag logTagWithName:@"NETWORKING" enabled:YES];
		_payloadTag = [ApptentiveLogTag logTagWithName:@"PAYLOAD" enabled:YES];
		_utilityTag = [ApptentiveLogTag logTagWithName:@"UTILITY" enabled:YES];
		_storageTag = [ApptentiveLogTag logTagWithName:@"STORAGE" enabled:YES];
		_logMonitorTag = [ApptentiveLogTag logTagWithName:@"LOG_MONITOR" enabled:YES];
	}
}

+ (instancetype)logTagWithName:(NSString *)name enabled:(BOOL)enabled {
	return [[self alloc] initWithName:name enabled:enabled];
}

- (instancetype)initWithName:(NSString *)name enabled:(BOOL)enabled {
	self = [super init];
	if (self) {
		_name = name;
		_enabled = enabled;
	}
	return self;
}

#pragma mark -
#pragma mark Tags

+ (ApptentiveLogTag *)conversationTag {
	return _conversationTag;
}

+ (ApptentiveLogTag *)networkTag {
	return _networkTag;
}

+ (ApptentiveLogTag *)payloadTag {
	return _payloadTag;
}

+ (ApptentiveLogTag *)utilityTag {
	return _utilityTag;
}

+ (ApptentiveLogTag *)storageTag {
	return _storageTag;
}

+ (ApptentiveLogTag *)logMonitorTag {
	return _logMonitorTag;
}

@end

NS_ASSUME_NONNULL_END
