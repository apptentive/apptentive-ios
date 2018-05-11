//
//  ApptentiveOrClause.m
//  Apptentive
//
//  Created by Frank Schmitt on 11/21/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveOrClause.h"
#import "ApptentiveFalseClause.h"
#import "ApptentiveAndClause.h"
#import "ApptentiveIndentPrinter.h"

NS_ASSUME_NONNULL_BEGIN

static NSString * const SubClausesKey = @"subClauses";


@interface ApptentiveOrClause ()

@property (strong, nonatomic) NSMutableArray *subClauses;

@end


@implementation ApptentiveOrClause

+ (ApptentiveClause *)orClauseWithArray:(NSArray *)array {
	if ([array isKindOfClass:[NSArray class]] && array.count == 1 && [array.firstObject isKindOfClass:[NSDictionary class]]) {
		return [ApptentiveAndClause andClauseWithDictionary:array.firstObject];
	}

	return [[self alloc] initWithArray:array];
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
			ApptentiveLogWarning(ApptentiveLogTagCriteria, @"Attempting to initialize $or clause with non-array parameter");
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
	[indentPrinter appendString:@"- $or"];
	[indentPrinter indent];

	for (ApptentiveClause *subClause in self.subClauses) {
		if ([subClause criteriaMetForConversation:conversation indentPrinter:indentPrinter]) {
			[indentPrinter outdent];
			return YES;
		}
	}

	[indentPrinter outdent];
	return NO;
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
