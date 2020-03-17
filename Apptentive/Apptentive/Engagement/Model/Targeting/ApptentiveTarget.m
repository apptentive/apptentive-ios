//
//  ApptentiveTarget.m
//  Apptentive
//
//  Created by Frank Schmitt on 11/21/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveTarget.h"
#import "ApptentiveAndClause.h"
#import "ApptentiveOrClause.h"
#import "ApptentiveNotClause.h"
#import "ApptentiveComparisonClause.h"
#import "ApptentiveFalseClause.h"

NS_ASSUME_NONNULL_BEGIN

static NSString * const InteractionIdentifierKey = @"interactionIdentifier";
static NSString * const CriteriaKey = @"criteria";

@implementation ApptentiveTarget

- (nullable instancetype)initWithDictionary:(NSDictionary *)dictionary {
	self = [super init];

	if (self) {
		if (![dictionary isKindOfClass:[NSDictionary class]]) {
			ApptentiveLogError(ApptentiveLogTagCriteria, @"Attempting to initialize target with non-dictionary parameter");
			return nil;
		}

		if (![dictionary[@"interaction_id"] isKindOfClass:[NSString class]] || [dictionary[@"interaction_id"] length] == 0) {
			ApptentiveLogError(ApptentiveLogTagCriteria, @"Apptenting to initialize target with invalid interaction identifier");
			return nil;
		}

		_interactionIdentifier = dictionary[@"interaction_id"];
		_criteria = [ApptentiveAndClause andClauseWithDictionary:dictionary[@"criteria"]];

		if (_criteria == nil) {
			ApptentiveLogError(ApptentiveLogTagCriteria, @"Attempting to initialize target with invalid criteria");
		}
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
		_interactionIdentifier = [coder decodeObjectOfClass:[NSString class] forKey:InteractionIdentifierKey];

		NSSet *allowedClasses = [NSSet setWithArray:@[
			[NSArray class],
			[ApptentiveTarget class],
			[ApptentiveAndClause class],
			[ApptentiveOrClause class],
			[ApptentiveNotClause class],
			[ApptentiveComparisonClause class],
			[ApptentiveFalseClause class]
		]];
		_criteria = [coder decodeObjectOfClasses:allowedClasses forKey:CriteriaKey];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
	[coder encodeObject:self.interactionIdentifier forKey:InteractionIdentifierKey];
	[coder encodeObject:self.criteria forKey:CriteriaKey];
}

@end

NS_ASSUME_NONNULL_END
