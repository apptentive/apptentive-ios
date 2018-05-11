//
//  ApptentiveNotClause.m
//  Apptentive
//
//  Created by Frank Schmitt on 11/21/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveNotClause.h"
#import "ApptentiveFalseClause.h"
#import "ApptentiveAndClause.h"
#import "ApptentiveIndentPrinter.h"

NS_ASSUME_NONNULL_BEGIN

static NSString * const SubClauseKey = @"subClause";


@interface ApptentiveNotClause ()

@property (strong, nonatomic) ApptentiveClause *subClause;

@end


@implementation ApptentiveNotClause

+ (instancetype)notClauseWithDictionary:(NSDictionary *)dictionary {
	return [[self alloc] initWithDictionary:dictionary];
}

- (instancetype)initWithDictionary:(NSDictionary *)dictionary {
	self = [super init];

	if (self) {
		if ([dictionary isKindOfClass:[NSDictionary class]]) {
			_subClause = [ApptentiveAndClause andClauseWithDictionary:dictionary];
		} else {
			ApptentiveLogWarning(ApptentiveLogTagCriteria, @"Attempting to initialize $not clause with non-dictionary parameter");
			_subClause = [ApptentiveFalseClause falseClauseWithObject:dictionary];
		}
	}

	return self;
}

- (BOOL)criteriaMetForConversation:(ApptentiveConversation *)conversation indentPrinter:(nonnull ApptentiveIndentPrinter *)indentPrinter {
	[indentPrinter appendString:@"- $not"];
	[indentPrinter indent];

	BOOL result = ![self.subClause criteriaMetForConversation:conversation indentPrinter:indentPrinter];

	[indentPrinter outdent];

	return result;
}

+ (BOOL)supportsSecureCoding {
	return YES;
}

- (nullable instancetype)initWithCoder:(NSCoder *)coder
{
	self = [super initWithCoder:coder];
	if (self) {
		_subClause = [coder decodeObjectForKey:SubClauseKey];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
	[coder encodeObject:self.subClause forKey:SubClauseKey];
}

@end

NS_ASSUME_NONNULL_END
