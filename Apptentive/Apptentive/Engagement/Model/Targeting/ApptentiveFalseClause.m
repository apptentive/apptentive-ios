//
//  ApptentiveFalseClause.m
//  Apptentive
//
//  Created by Frank Schmitt on 11/21/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveFalseClause.h"
#import "ApptentiveIndentPrinter.h"

NS_ASSUME_NONNULL_BEGIN

static NSString * const InvalidCriteriaDescriptionKey = @"invalidCriteriaDescription";

@interface ApptentiveFalseClause ()

@property (readonly, nonatomic) NSString *invalidCriteriaDescription;

@end

@implementation ApptentiveFalseClause

+ (instancetype)falseClauseWithObject:(NSObject *)object {
	return [[self alloc] initWithDescriptionObject:object];
}

- (instancetype)initWithDescriptionObject:(NSObject *)object {
	self = [super init];

	if (self) {
		_invalidCriteriaDescription = object.debugDescription;
		ApptentiveLogWarning(ApptentiveLogTagCriteria, @"Criteria parser found invalid or unrecognized criteria “%@”", _invalidCriteriaDescription);
	}

	return self;
}

- (BOOL)criteriaMetForConversation:(ApptentiveConversation *)conversation indentPrinter:(ApptentiveIndentPrinter *)indentPrinter {
	[indentPrinter appendFormat:@"- Invalid or unrecognized criteria (“%@”). Evaluates to false.", self.invalidCriteriaDescription];
	return NO;
}

+ (BOOL)supportsSecureCoding {
	return YES;
}

- (nullable instancetype)initWithCoder:(NSCoder *)coder
{
	self = [super init];
	if (self) {
		_invalidCriteriaDescription = [coder decodeObjectOfClass:[NSString class] forKey:InvalidCriteriaDescriptionKey];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
	[coder encodeObject:self.invalidCriteriaDescription forKey:InvalidCriteriaDescriptionKey];
}

@end

NS_ASSUME_NONNULL_END
