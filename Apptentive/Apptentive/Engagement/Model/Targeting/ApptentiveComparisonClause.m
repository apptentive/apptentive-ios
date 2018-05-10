//
//  ApptentiveComparisonClause.m
//  Apptentive
//
//  Created by Frank Schmitt on 11/21/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveComparisonClause.h"
#import "ApptentiveFalseClause.h"
#import "ApptentiveVersion.h"
#import "ApptentiveConversation.h"
#import "ApptentiveIndentPrinter.h"

NS_ASSUME_NONNULL_BEGIN

static NSString * const FieldKey = @"field";
static NSString * const ComparisonsKey = @"comparisons";

static NSString * trimmedAndLowercased(NSObject *string) {
	return [[(NSString *)string lowercaseString] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

static BOOL canCompare(NSObject *value, NSObject *parameter, NSComparisonResult *comparisonResult) {
	BOOL bothNull = (value == nil) && [parameter isKindOfClass:[NSNull class]];
	if (bothNull) {
		if (comparisonResult != nil) {
			*comparisonResult = NSOrderedSame;
		}

		return YES;
	}

	BOOL bothStrings = ([value isKindOfClass:[NSString class]] && [parameter isKindOfClass:[NSString class]]);
	BOOL bothNumbers = ([value isKindOfClass:[NSNumber class]] && [parameter isKindOfClass:[NSNumber class]]);
	BOOL bothDates = ([value isKindOfClass:[NSDate class]] && [parameter isKindOfClass:[NSDate class]]);
	BOOL bothVersions = ([value isKindOfClass:[ApptentiveVersion class]] && [parameter isKindOfClass:[ApptentiveVersion class]]);

	BOOL canCompare = bothStrings || bothNumbers || bothDates || bothVersions;

	if (bothStrings) {
		value = trimmedAndLowercased(value);
		parameter = trimmedAndLowercased(parameter);
	}

	if (canCompare && comparisonResult != nil) {
		*comparisonResult = (NSComparisonResult)[value performSelector:@selector(compare:) withObject:parameter];
	}

	return canCompare;
}

@implementation ApptentiveComparisonClause

+ (NSDictionary *)operators {
	static NSDictionary *_operators;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		_operators = @{
					   @"$exists": ^(NSObject * _Nonnull value, NSObject * parameter){
						   if (![parameter isKindOfClass:[NSNumber class]]) {
							   return NO;
						   }

						   BOOL shouldExist = ((NSNumber *)parameter).integerValue == 1;
						   return (BOOL)((value != nil) == shouldExist);
					   },
					   @"$eq":^(NSObject * _Nonnull value, NSObject * parameter){
						   NSComparisonResult result;
						   return canCompare(value, parameter, &result) && result == NSOrderedSame;
					   },
					   @"$ne":^(NSObject * _Nonnull value, NSObject * parameter){
						   NSComparisonResult result;
						   return canCompare(value, parameter, &result) && result != NSOrderedSame;
					   },
					   @"$lt":^(NSObject * _Nonnull value, NSObject * parameter){
						   NSComparisonResult result;
						   return canCompare(value, parameter, &result) && result == NSOrderedAscending;
					   },
					   @"$lte":^(NSObject * _Nonnull value, NSObject * parameter){
						   NSComparisonResult result;
						   return canCompare(value, parameter, &result) && (result == NSOrderedAscending || result == NSOrderedSame);
					   },
					   @"$gt":^(NSObject * _Nonnull value, NSObject * parameter){
						   NSComparisonResult result;
						   return canCompare(value, parameter, &result) && result == NSOrderedDescending;
					   },
					   @"$gte":^(NSObject * _Nonnull value, NSObject * parameter){
						   NSComparisonResult result;
						   return canCompare(value, parameter, &result) && (result == NSOrderedDescending || result == NSOrderedSame);
					   },
					   @"$before":^(NSObject * _Nonnull value, NSObject * parameter){
						   NSComparisonResult result;
						   return [value isKindOfClass:[NSDate class]] && canCompare(value, parameter, &result) && result == NSOrderedAscending;
					   },
					   @"$after":^(NSObject * _Nonnull value, NSObject * parameter){
						   NSComparisonResult result;
						   return [value isKindOfClass:[NSDate class]] && canCompare(value, parameter, &result) && result == NSOrderedDescending;
					   },
					   @"$contains":^(NSObject * _Nonnull value, NSObject * parameter){
						   return [value isKindOfClass:[NSString class]] && [parameter isKindOfClass:[NSString class]] && [trimmedAndLowercased(value) containsString:trimmedAndLowercased(parameter)];
					   },
					   @"$starts_with":^(NSObject * _Nonnull value, NSObject * parameter){
						   return [value isKindOfClass:[NSString class]] && [parameter isKindOfClass:[NSString class]] && [trimmedAndLowercased(value) hasPrefix:trimmedAndLowercased(parameter)];
					   },
					   @"$ends_with":^(NSObject * _Nonnull value, NSObject * parameter){
						   return [value isKindOfClass:[NSString class]] && [parameter isKindOfClass:[NSString class]] && [trimmedAndLowercased(value) hasSuffix:trimmedAndLowercased(parameter)];
					   }
					   };
	});

	return _operators;
}

+ (ApptentiveClause *)comparisonClauseWithField:(NSString *)field comparisons:(NSDictionary *)comparisons {
	BOOL fieldIsString = [field isKindOfClass:[NSString class]];
	BOOL valueIsImplicitEquals = ![comparisons isKindOfClass:[NSDictionary class]] || [(NSDictionary *)comparisons objectForKey:@"_type"] != nil;
	BOOL valueIsComparison = [comparisons isKindOfClass:[NSDictionary class]] && [(NSDictionary *)comparisons objectForKey:@"_type"] == nil;
	if (!fieldIsString || !(valueIsImplicitEquals || valueIsComparison)) {
		ApptentiveLogWarning(ApptentiveLogTagCriteria, @"Attempting to initialize comparison clause with invalid key or value (“%@” = ”%@”).", field, comparisons);
		return [ApptentiveFalseClause falseClauseWithObject:[NSString stringWithFormat:@"(“%@” = ”%@”).", field, comparisons]];
	}

	else if (valueIsImplicitEquals) {
		comparisons = @{ @"$eq": comparisons };
	}

	return [[self alloc] initWithField:field comparisons:comparisons];
}

- (instancetype)initWithField:(NSString *)field comparisons:(NSDictionary *)comparisons {
	self = [super init];

	if (self) {
		_field = [field stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		_comparisons = comparisons;
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
		_field = [coder decodeObjectOfClass:[NSString class] forKey:FieldKey];
		_comparisons = [coder decodeObjectOfClass:[NSDictionary class] forKey:ComparisonsKey];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
	[coder encodeObject:self.field forKey:FieldKey];
	[coder encodeObject:self.comparisons forKey:ComparisonsKey];
}

- (NSObject *)valueInConversation:(ApptentiveConversation *)conversation {
	return [conversation valueForFieldWithPath:self.field];
}

- (BOOL)criteriaMetForConversation:(ApptentiveConversation *)conversation indentPrinter:(nonnull ApptentiveIndentPrinter *)indentPrinter {
	NSObject *value = [self valueInConversation:conversation];

	for (NSString *operator in self.comparisons) {
		ComparisonBlock comparisonBlock = [[self class] operators][operator];
		if (comparisonBlock == nil) {
			ApptentiveLogWarning(ApptentiveLogTagCriteria, @"Unrecognized operator “%@”. Evaluates to false", operator);
			return NO;
		}

		NSObject *parameter = self.comparisons[operator];

		if ([parameter isKindOfClass:[NSDictionary class]]) {
			NSDictionary *parameterDictionary = (NSDictionary *)parameter;
			NSString *type = parameterDictionary[@"_type"];

			if ([type isEqualToString:@"datetime"] && [parameterDictionary[@"sec"] isKindOfClass:[NSNumber class]]) {
				parameter = [NSDate dateWithTimeIntervalSince1970:((NSNumber *)parameterDictionary[@"sec"]).doubleValue];
			} else if ([type isEqualToString:@"version"] && [parameterDictionary[@"version"] isKindOfClass:[NSString class]]) {
				parameter = [[ApptentiveVersion alloc] initWithString:(NSString *)parameterDictionary[@"version"]];
			} else if (type == nil) {
				ApptentiveLogWarning(ApptentiveLogTagCriteria, @"Complex type with no “_type” key. Evaluates to false.");
				return NO;
			} else {
				ApptentiveLogWarning(ApptentiveLogTagCriteria, @"Unrecognized or malformed complex type “%@”. Evaluates to false.", type);
				return NO;
			}
		}

		if ([operator isEqualToString:@"$before"] || [operator isEqualToString:@"$after"]) {
			if ([parameter isKindOfClass:[NSNumber class]]) {
				parameter = [conversation.currentTime dateByAddingTimeInterval:((NSNumber *)parameter).doubleValue];
			} else {
				ApptentiveLogWarning(ApptentiveLogTagCriteria, @"“%@” operator with non-numeric parameter (“%@”). Evaluates to false", operator, parameter);
			}
		}

		BOOL result = comparisonBlock(value, parameter);
		[indentPrinter appendFormat:@"- %@ ('%@') %@ '%@' => %@", [conversation descriptionForFieldWithPath:self.field], value, [self friendlyNameForOperator:operator], parameter, result ? @"true" : @"false"];
		if (!result) {
			return NO;
		}
	}

	return YES;
}

- (NSString *)friendlyNameForOperator:(NSString *)operator {
	static NSDictionary *friendlyTrueOperators;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		friendlyTrueOperators = @{
							  @"$eq": @"is equal to",
							  @"$ne": @"is not equal to",
							  @"$lt": @"is less than",
							  @"$lte": @"is less than or equal to",
							  @"$gt": @"is greater than",
							  @"$gte": @"is greater than or equal to",
							  @"$starts_with": @"starts with",
							  @"$ends_with": @"ends with",
							  @"$contains": @"contains",
							  @"$after": @"is after",
							  @"$before": @"is before",
							  @"$exists": @"exists"
							  };
	});

	NSString *result = friendlyTrueOperators[operator];

	if (result) {
		return result;
	} else {
		return @"Unrecognized Operator";
	}
}

@end

NS_ASSUME_NONNULL_END
