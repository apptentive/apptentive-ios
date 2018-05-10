//
//  ApptentiveClause.m
//  Apptentive
//
//  Created by Frank Schmitt on 11/21/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveClause.h"
#import "ApptentiveFalseClause.h"
#import "ApptentiveAndClause.h"
#import "ApptentiveOrClause.h"
#import "ApptentiveNotClause.h"
#import "ApptentiveIndentPrinter.h"

NS_ASSUME_NONNULL_BEGIN

@implementation ApptentiveClause

- (BOOL)criteriaMetForConversation:(ApptentiveConversation *)conversation indentPrinter:(ApptentiveIndentPrinter *)indentPrinter {
	ApptentiveLogError(ApptentiveLogTagCriteria, @"Abstract method called. Returning NO.");
	return NO;
}

- (BOOL)criteriaMetForConversation:(ApptentiveConversation *)conversation {
	ApptentiveIndentPrinter *indentPrinter = [[ApptentiveIndentPrinter alloc] init];

	BOOL result = [self criteriaMetForConversation:conversation indentPrinter:indentPrinter];

	ApptentiveLogDebug(@"Criteria Evaluation Details:\n%@", indentPrinter.output);
	
	return result;
}

+ (BOOL)supportsSecureCoding {
	return YES;
}

- (nullable instancetype)initWithCoder:(NSCoder *)coder
{
	return [super init];
}

- (void)encodeWithCoder:(NSCoder *)coder
{
}

@end

NS_ASSUME_NONNULL_END
