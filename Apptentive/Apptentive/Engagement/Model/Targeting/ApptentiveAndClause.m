//
//  ApptentiveAndClause.m
//  Apptentive
//
//  Created by Frank Schmitt on 11/21/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveAndClause.h"
#import "ApptentiveFalseClause.h"
#import "ApptentiveComparisonClause.h"
#import "ApptentiveOrClause.h"
#import "ApptentiveNotClause.h"
#import "ApptentiveIndentPrinter.h"

NS_ASSUME_NONNULL_BEGIN

static NSString * const SubClausesKey = @"subClauses";


@interface ApptentiveAndClause ()

@property (strong, nonatomic) NSMutableArray *subClauses;

@end


@implementation ApptentiveAndClause

+ (ApptentiveClause *)andClauseWithDictionary:(NSDictionary *)dictionary {
	return [[self alloc] initWithDictionary:dictionary];
}

+ (ApptentiveClause *)andClauseWithArray:(NSArray *)array {
	return [[self alloc] initWithArray:array];
}

- (instancetype)initWithDictionary:(NSDictionary *)dictionary {
	self = [super init];

	if (self) {
		_subClauses = [NSMutableArray arrayWithCapacity:dictionary.count];

		if ([dictionary isKindOfClass:[NSDictionary class]]) {
			for (NSString *key in dictionary) {
				if ([key isEqualToString:@"$and"]) {
					[_subClauses addObject:[ApptentiveAndClause andClauseWithArray:dictionary[key]]];
				} else if ([key isEqualToString:@"$or"]) {
					[_subClauses addObject:[ApptentiveOrClause orClauseWithArray:dictionary[key]]];
				} else if ([key isEqualToString:@"$not"]) {
					[_subClauses addObject:[ApptentiveNotClause notClauseWithDictionary:dictionary[key]]];
				} else if ([key hasPrefix:@"$"]) {
					ApptentiveLogWarning(ApptentiveLogTagCriteria, @"Unrecognized logical operator “%@”. Evaluates to false.", key);
					[_subClauses addObject:[ApptentiveFalseClause falseClauseWithObject:dictionary[key]]];
				} else {
					[_subClauses addObject:[ApptentiveComparisonClause comparisonClauseWithField:key comparisons:dictionary[key]]];
				}
			}
		} else {
			ApptentiveLogWarning(ApptentiveLogTagCriteria, @"Attempting to initialize implicit $and clause with non-dictionary parameter");
			[_subClauses addObject:[ApptentiveFalseClause falseClauseWithObject:dictionary]];
		}
	}

	return self;
}

- (instancetype)initWithArray:(NSArray *)array {
	self = [super init];

	if (self) {
		_subClauses = [NSMutableArray arrayWithCapacity:array.count];

		if ([array isKindOfClass:[NSArray class]]) {
			for (NSDictionary *clauseDictionary in array) {
				ApptentiveClause *subClause = [ApptentiveAndClause andClauseWithDictionary:clauseDictionary];

				[_subClauses addObject:subClause];
			}
		} else {
			ApptentiveLogWarning(ApptentiveLogTagCriteria, @"Attempting to initialize $and clause with non-array parameter");
			[_subClauses addObject:[ApptentiveFalseClause falseClauseWithObject:array]];
		}
	}

	return self;
}

- (instancetype)init{
	self = [super init];
	if (self) {
		_subClauses = [NSMutableArray array];
	}
	return self;
}

- (BOOL)criteriaMetForConversation:(ApptentiveConversation *)conversation indentPrinter:(nonnull ApptentiveIndentPrinter *)indentPrinter {
	BOOL shouldNest = self.subClauses.count > 1;
	if (shouldNest) {
		[indentPrinter appendString:@"- $and"];
		[indentPrinter indent];
	}

	for (ApptentiveClause *subClause in self.subClauses) {
		if (![subClause criteriaMetForConversation:conversation indentPrinter:indentPrinter]) {
			if (shouldNest) {
				[indentPrinter outdent];
			}
			return NO;
		}
	}

	if (shouldNest) {
		[indentPrinter outdent];
	}
	return YES;
}

+ (BOOL)supportsSecureCoding {
	return YES;
}

- (nullable instancetype)initWithCoder:(NSCoder *)coder
{
	self = [super initWithCoder:coder];
	if (self) {
		_subClauses = [coder decodeObjectForKey:SubClausesKey];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
	[coder encodeObject:self.subClauses forKey:SubClausesKey];
}

@end

NS_ASSUME_NONNULL_END
