//
//  ApptentiveTargets.m
//  Apptentive
//
//  Created by Frank Schmitt on 11/21/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveTargets.h"
#import "ApptentiveInvocations.h"

NS_ASSUME_NONNULL_BEGIN

static NSString * const InvocationsKey = @"invocations";

@implementation ApptentiveTargets

- (nullable instancetype)initWithTargetsDictionary:(NSDictionary <NSString *, NSArray *>*)targetsDictionary {
	self = [super init];

	if (self) {
		if (![targetsDictionary isKindOfClass:[NSDictionary class]]) {
			ApptentiveLogError(@"targets is not a dictionary");
			return nil;
		}

		NSMutableDictionary *invocations = [NSMutableDictionary dictionaryWithCapacity:targetsDictionary.count];

		for (NSString *event in targetsDictionary) {
			if (![targetsDictionary[event] isKindOfClass:[NSArray class]]) {
				ApptentiveLogError(@"target value is not an array");
				continue;
			}

			invocations[event] = [[ApptentiveInvocations alloc] initWithArray:targetsDictionary[event]];
		}

		_invocations = [invocations copy];
	}

	return self;
}

+ (BOOL)supportsSecureCoding {
	return YES;
}

- (nullable instancetype)initWithCoder:(NSCoder *)coder
{
	self = [super init];
	if (self) {
		_invocations = [coder decodeObjectOfClass:[NSDictionary class] forKey:InvocationsKey];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
	[coder encodeObject:self.invocations forKey:InvocationsKey];
}

- (nullable NSString *)interactionIdentifierForEvent:(NSString *)event conversation:(ApptentiveConversation *)conversation {
	ApptentiveInvocations *invocationsForEvent = self.invocations[event];

	return [invocationsForEvent interactionIdentifierForConversation:conversation];
}

@end

NS_ASSUME_NONNULL_END

