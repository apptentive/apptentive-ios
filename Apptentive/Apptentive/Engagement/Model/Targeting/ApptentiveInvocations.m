//
//  ApptentiveInvocations.m
//  Apptentive
//
//  Created by Frank Schmitt on 11/22/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveInvocations.h"
#import "ApptentiveTarget.h"
#import "ApptentiveClause.h"
#import "ApptentiveIndentPrinter.h"

NS_ASSUME_NONNULL_BEGIN

static NSString * const TargetsKey = @"targets";

@implementation ApptentiveInvocations

- (instancetype)initWithArray:(NSArray *)targetsArray {
	self = [super init];

	if (self) {
		NSMutableArray *targets = [NSMutableArray arrayWithCapacity:targetsArray.count];

		for (NSDictionary *rawTarget in targetsArray) {
			ApptentiveTarget *target = [[ApptentiveTarget alloc] initWithDictionary:rawTarget];

			if (target) {
				[targets addObject:target];
			}
		}

		_targets = targets;
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
		_targets = [coder decodeObjectOfClass:[NSArray class] forKey:TargetsKey];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
	[coder encodeObject:self.targets forKey:TargetsKey];
}

- (nullable NSString *)interactionIdentifierForConversation:(ApptentiveConversation *)conversation {
	if (self.targets.count == 0) {
		ApptentiveLogDebug(ApptentiveLogTagCriteria, @"No interactions configured with this Where event");
		return nil;
	}

	for (ApptentiveTarget *target in self.targets) {
		@autoreleasepool {
			ApptentiveIndentPrinter *indentPrinter = [[ApptentiveIndentPrinter alloc] init];
			if ([target.criteria criteriaMetForConversation:conversation indentPrinter:indentPrinter]) {
				ApptentiveLogInfo(ApptentiveLogTagCriteria, @"Criteria for interaction '%@' evaluated => true", target.interactionIdentifier);
				if (indentPrinter.output.length) {
					ApptentiveLogDebug(ApptentiveLogTagCriteria, @"Criteria Evaluation Details:\n%@", indentPrinter.output);
				}
				return target.interactionIdentifier;
			}

			ApptentiveLogInfo(ApptentiveLogTagCriteria, @"Criteria for interaction '%@' evaluated => false", target.interactionIdentifier);
			if (indentPrinter.output.length) {
				ApptentiveLogDebug(ApptentiveLogTagCriteria, @"Criteria Evaluation Details:\n%@", indentPrinter.output);
			}
		}
	}

	ApptentiveLogDebug(ApptentiveLogTagCriteria, @"No interactions configured with this Where event had matching Who/When criteria");
	return nil;
}

@end

NS_ASSUME_NONNULL_END
