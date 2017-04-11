//
//  ApptentiveLogTag.m
//  Apptentive
//
//  Created by Alex Lementuev on 3/29/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveLogTag.h"

static ApptentiveLogTag *_conversationTag;


@implementation ApptentiveLogTag


+ (void)initialize {
	if ([self class] == [ApptentiveLogTag class]) {
		_conversationTag = [ApptentiveLogTag logTagWithName:@"CONVERSATION" enabled:YES];
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

@end
