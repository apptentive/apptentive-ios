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
static ApptentiveLogTag *_criteriaTag;
static ApptentiveLogTag *_interactionsTag;
static ApptentiveLogTag *_pushTag;
static ApptentiveLogTag *_messagesTag;
static ApptentiveLogTag *_apptimizeTag;


@implementation ApptentiveLogTag


+ (void)initialize {
	if ([self class] == [ApptentiveLogTag class]) {
		_conversationTag = [ApptentiveLogTag logTagWithName:@"CONVERSATION"];
		_networkTag = [ApptentiveLogTag logTagWithName:@"NETWORK"];
		_payloadTag = [ApptentiveLogTag logTagWithName:@"PAYLOADS"];
		_utilityTag = [ApptentiveLogTag logTagWithName:@"UTIL"];
		_storageTag = [ApptentiveLogTag logTagWithName:@"STORAGE"];
		_logMonitorTag = [ApptentiveLogTag logTagWithName:@"LOG_MONITOR"];
		_interactionsTag = [ApptentiveLogTag logTagWithName:@"INTERACTIONS"];
		_pushTag = [ApptentiveLogTag logTagWithName:@"PUSH"];
		_messagesTag = [ApptentiveLogTag logTagWithName:@"MESSAGES"];
		_criteriaTag = [ApptentiveLogTag logTagWithName:@"CRITERIA"];
		_apptimizeTag = [ApptentiveLogTag logTagWithName:@"APPTIMIZE"];
	}
}

+ (instancetype)logTagWithName:(NSString *)name {
	return [[self alloc] initWithName:name];
}

- (instancetype)initWithName:(NSString *)name {
	self = [super init];
	if (self) {
		_name = name;
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

+ (ApptentiveLogTag *)criteriaTag {
	return _criteriaTag;
}

+ (ApptentiveLogTag *)interactionsTag {
	return _logMonitorTag;
}

+ (ApptentiveLogTag *)pushTag {
	return _logMonitorTag;
}

+ (ApptentiveLogTag *)messagesTag {
	return _logMonitorTag;
}

+ (ApptentiveLogTag *)apptimizeTag {
	return _apptimizeTag;
}

@end

NS_ASSUME_NONNULL_END
