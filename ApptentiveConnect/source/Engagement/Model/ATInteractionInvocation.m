//
//  ATInteractionInvocation.m
//  ApptentiveConnect
//
//  Created by Peter Kamb on 12/10/14.
//  Copyright (c) 2014 Apptentive, Inc. All rights reserved.
//

#import "ATInteractionInvocation.h"

#import "ATEngagementBackend.h"
#import "ATInteractionUsageData.h"
#import "ATUtilities.h"

@implementation ATInteractionInvocation

+ (ATInteractionInvocation *)invocationWithJSONDictionary:(NSDictionary *)jsonDictionary {
	ATInteractionInvocation *invocation = [[ATInteractionInvocation alloc] init];
	invocation.interactionID = jsonDictionary[@"interaction_id"];
	invocation.priority = [jsonDictionary[@"priority"] integerValue];
	invocation.criteria = jsonDictionary[@"criteria"];
	
	return invocation;
}

+ (NSArray *)invocationsWithJSONArray:(NSArray *)jsonArray {
	NSMutableArray *invocations = [NSMutableArray array];

	for (NSObject *invocationObject in jsonArray) {
		ATInteractionInvocation *invocation = nil;
		
		// Handle arrays of both Invocation and NSDictionary
		if ([invocationObject isKindOfClass:[ATInteractionInvocation class]]) {
			invocation = (ATInteractionInvocation *)invocationObject;
		}
		else if ([invocationObject isKindOfClass:[NSDictionary class]]) {
			invocation = [ATInteractionInvocation invocationWithJSONDictionary:(NSDictionary *)invocationObject];
		}
		
		if (invocation) {
			[invocations addObject:invocation];
		}
	}
	
	return invocations;
}

- (NSString *)description {
	NSDictionary *description = @{@"interaction_id" : self.interactionID ?: [NSNull null],
								  @"priority" : [NSNumber numberWithInteger:self.priority] ?: [NSNull null],
								  @"criteria" : self.criteria ?: [NSNull null]};
	
	return [description description];
}

- (id)initWithCoder:(NSCoder *)coder {
	if ((self = [super init])) {
		self.interactionID = [coder decodeObjectForKey:@"interactionID"];
		self.priority = [coder decodeIntegerForKey:@"priority"];
		self.criteria = [coder decodeObjectForKey:@"criteria"];
	}
	
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
	[coder encodeObject:self.interactionID forKey:@"interactionID"];
	[coder encodeInteger:self.priority forKey:@"priority"];
	[coder encodeObject:self.criteria forKey:@"criteria"];
}

- (id)copyWithZone:(NSZone *)zone {
	ATInteractionInvocation *copy = [[ATInteractionInvocation alloc] init];
	
	if (copy) {
		copy.interactionID = self.interactionID;
		copy.priority = self.priority;
		copy.criteria = self.criteria;
	}
	
	return copy;
}

- (BOOL)isValid {
	BOOL isValid = NO;
	
	do { // once
		if (![self criteriaAreMet]) {
			break;
		}
		
		isValid = YES;
	} while (NO);
	
	return isValid;
}

- (BOOL)criteriaAreMet {
	return [self criteriaAreMetForUsageData:[ATInteractionUsageData usageData]];
}

- (BOOL)criteriaAreMetForUsageData:(ATInteractionUsageData *)usageData {
	BOOL criteriaAreMet = NO;
	
	if (!self.criteria) {
		// Interactions without a criteria object should evaluate to FALSE.
		criteriaAreMet = NO;
	} else if (self.criteria && self.criteria.count == 0) {
		// Interactions with no keys in the criteria dictionary should evaluate to TRUE.
		criteriaAreMet = YES;
	} else {
		@try {
			NSPredicate *predicate = [self criteriaPredicate];
			if (predicate) {
				criteriaAreMet = [predicate evaluateWithObject:[usageData predicateEvaluationDictionary]];
				if (!criteriaAreMet) {
					//TODO: Log this information in a more user friendly and useful way.
					
					//ATLogInfo(@"Interaction predicate failed evaluation.");
					//ATLogInfo(@"Predicate: %@", predicate);
					//ATLogInfo(@"Interaction usage data: %@", [usageData predicateEvaluationDictionary]);
				}
			} else {
				ATLogError(@"Could not create a valid criteria predicate for the Interaction criteria: %@", self.criteria);
				criteriaAreMet = NO;
			}
		}
		@catch (NSException *exception) {
			ATLogError(@"Exception while processing criteria.");
			criteriaAreMet = NO;
		}
	}
	
	return criteriaAreMet;
}

- (NSPredicate *)criteriaPredicate {
	NSPredicate *criteriaPredicate = [ATInteractionInvocation compoundPredicateWithCriteria:self.criteria];
	
	return criteriaPredicate;
}

+ (NSCompoundPredicate *)compoundPredicateWithCriteria:(NSDictionary *)criteria {
	NSMutableArray *subPredicates = [NSMutableArray array];
	
	for (NSString *key in criteria) {
		NSObject *value = [criteria objectForKey:key];

		NSPredicate *predicate = nil;
		
		if ([value isKindOfClass:[NSArray class]]) {
			BOOL hasError;
			NSCompoundPredicateType predicateType = [self compoundPredicateTypeFromString:key hasError:&hasError];
			if (!hasError) {
				predicate = [self compoundPredicateWithType:predicateType criteriaArray:(NSArray *)value];
			}
		} else if ([value isKindOfClass:[NSDictionary class]]) {
			NSDictionary *dictionaryValue = (NSDictionary *)value;
			if ([dictionaryValue.allKeys.firstObject isEqualToString:@"$not"]) {
				NSString *notKey = dictionaryValue.allKeys.firstObject;
				BOOL hasError;
				NSCompoundPredicateType predicateType = [self compoundPredicateTypeFromString:notKey hasError:&hasError];
				if (!hasError) {
					predicate = [self compoundPredicateWithType:predicateType criteriaArray:@[@{key: dictionaryValue[notKey]}]];
				}
			} else {
				predicate = [self compoundPredicateForKeyPath:key operatorsAndValues:(NSDictionary *)value];
			}
		} else if ([value isKindOfClass:[NSString class]] || [value isKindOfClass:[NSNumber class]]) {
			NSDictionary *implicitEquality = @{@"==": value};
			predicate = [self compoundPredicateForKeyPath:key operatorsAndValues:implicitEquality];
		}
		
		if (predicate) {
			[subPredicates addObject:predicate];
		} else {
			return nil;
		}
	}
	
	NSCompoundPredicate *compoundPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:subPredicates];
	
	return compoundPredicate;
}

+ (NSCompoundPredicate *)compoundPredicateWithType:(NSCompoundPredicateType)type criteriaArray:(NSArray *)criteriaArray{
	NSMutableArray *subPredicates = [NSMutableArray array];
	
	for (NSDictionary *criteria in criteriaArray) {
		NSPredicate *predicate = [self compoundPredicateWithCriteria:criteria];
		if (predicate) {
			[subPredicates addObject:predicate];
		} else {
			return nil;
		}
	}
	
	NSCompoundPredicate *compoundPredicate = [[NSCompoundPredicate alloc] initWithType:type subpredicates:subPredicates];
	
	return compoundPredicate;
}

+ (NSCompoundPredicate *)compoundPredicateForKeyPath:(NSString *)keyPath operatorsAndValues:(NSDictionary *)operatorsAndValues {
	NSMutableArray *subPredicates = [NSMutableArray array];
	
	for (NSString *operatorString in operatorsAndValues) {
		NSObject *value = operatorsAndValues[operatorString];
		
		NSPredicate *predicate = nil;
		
		if ([operatorString isEqualToString:@"$exists"]) {
			if ([value isKindOfClass:[NSNumber class]]) {
				NSString *predicateFormatString = [[@"(%K " stringByAppendingString:([(NSNumber *)value boolValue] ? @"!=" : @"==")] stringByAppendingString:@" nil)"];
				predicate = [NSPredicate predicateWithFormat:predicateFormatString, keyPath];
			}
		} else if ([value isKindOfClass:[NSString class]] || [value isKindOfClass:[NSNumber class]]) {
			BOOL hasError;
			
			NSPredicateOperatorType operatorType = [self predicateOperatorTypeFromString:operatorString hasError:&hasError];
			if (!hasError) {
				predicate = [self predicateWithLeftKeyPath:keyPath rightValue:value operatorType:operatorType];
			}
		} else if ([value isKindOfClass:[NSDictionary class]]) {
			predicate = [NSCompoundPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
				BOOL hasError;
				NSPredicateOperatorType operatorType = [self predicateOperatorTypeFromString:operatorString hasError:&hasError];
				if (!hasError) {
					NSComparisonPredicate *predicate = [self predicateWithLeftComplexObject:evaluatedObject rightComplexObject:(NSDictionary *)value operatorType:operatorType];
					
					return [predicate evaluateWithObject:nil];
				} else {
					return NO;
				}
			}];
		}
		
		if (predicate) {
			[subPredicates addObject:predicate];
		} else {
			return nil;
		}
	}
	
	NSCompoundPredicate *compountPredicate = [[NSCompoundPredicate alloc] initWithType:NSAndPredicateType subpredicates:subPredicates];

	return compountPredicate;
}

+ (NSComparisonPredicate *)predicateWithLeftKeyPath:(NSString *)leftKeyPath rightValue:(nullable id)rightValue operatorType:(NSPredicateOperatorType)operatorType {
	
	[ATInteractionUsageData keyPathWasSeen:leftKeyPath];
	
	NSExpression *leftExpression = [NSExpression expressionForKeyPath:leftKeyPath];
	NSExpression *rightExpression = [NSExpression expressionForConstantValue:rightValue];
	
	return [self predicateWithLeftExpression:leftExpression rightExpression:rightExpression operatorType:operatorType];
}

+ (NSComparisonPredicate *)predicateWithLeftComplexObject:(NSDictionary *)leftComplexObject rightComplexObject:(NSDictionary *)rightComplexObject operatorType:(NSPredicateOperatorType)operatorType {
	NSString *type = leftComplexObject[@"_type"];
	NSString *rightType = rightComplexObject[@"_type"];
	if (![type isEqualToString:rightType]) {
		ATLogError(@"Criteria Complex Type objects must be of the same type!");
		return nil;
	}
	
	NSObject *leftValue;
	NSObject *rightValue;
	
	if ([type isEqualToString:@"version"]) {
		NSString *leftVersion = leftComplexObject[@"version"];
		NSString *rightVersion = rightComplexObject[@"version"];
		
		NSComparisonResult result = [ATUtilities compareVersionString:leftVersion toVersionString:rightVersion];
		
		switch (result) {
			case NSOrderedAscending:
				leftValue = @0;
				rightValue = @1;
				break;
			case NSOrderedDescending:
				leftValue = @1;
				rightValue = @0;
				break;
			case NSOrderedSame:
				leftValue = @1;
				rightValue = @1;
				break;
		}
	} else if ([type isEqualToString:@"datetime"]) {
		leftValue = leftComplexObject[@"sec"];
		rightValue = rightComplexObject[@"sec"];
	}
	else if ([type isEqualToString:@"duration"]) {
		leftValue = leftComplexObject[@"sec"];
		rightValue = rightComplexObject[@"sec"];
	}
	
	NSComparisonPredicate *predicate = [self predicateWithLeftValue:leftValue rightValue:rightValue operatorType:operatorType];
	
	return predicate;
}

+ (NSComparisonPredicate *)predicateWithLeftValue:(nullable id)leftValue rightValue:(nullable id)rightValue operatorType:(NSPredicateOperatorType)operatorType {
	NSExpression *leftExpression = [NSExpression expressionForConstantValue:leftValue];
	NSExpression *rightExpression = [NSExpression expressionForConstantValue:rightValue];
	
	return [self predicateWithLeftExpression:leftExpression rightExpression:rightExpression operatorType:operatorType];
}

+ (NSComparisonPredicate *)predicateWithLeftExpression:(NSExpression *)leftExpression rightExpression:(NSExpression *)rightExpression operatorType:(NSPredicateOperatorType)operatorType {
	NSComparisonPredicateOptions options;
	switch (operatorType) {
		case NSContainsPredicateOperatorType:
		case NSBeginsWithPredicateOperatorType:
		case NSEndsWithPredicateOperatorType:
			options = NSCaseInsensitivePredicateOption;
			break;
		default:
			options = 0;
			break;
	}
	
	NSComparisonPredicate *predicate = [NSComparisonPredicate predicateWithLeftExpression:leftExpression
																		  rightExpression:rightExpression
																				 modifier:NSDirectPredicateModifier
																					 type:operatorType
																				  options:options];
	return predicate;
}

+ (NSCompoundPredicateType)compoundPredicateTypeFromString:(NSString *)predicateTypeString hasError:(nonnull BOOL *)hasError {
	*hasError = NO;
	if ([predicateTypeString isEqualToString:@"$and"]) {
		return NSAndPredicateType;
	} else if ([predicateTypeString isEqualToString:@"$or"]) {
		return NSOrPredicateType;
	} else if ([predicateTypeString isEqualToString:@"$not"]) {
		return NSNotPredicateType;
	} else {
		ATLogError(@"Expected `$and`, `$or`, or `$not` skey; instead saw key: %@", predicateTypeString);
		*hasError = YES;
		return NSAndPredicateType;
	}
}

+ (NSPredicateOperatorType)predicateOperatorTypeFromString:(NSString *)operatorString hasError:(nonnull BOOL *)hasError {
	*hasError = NO;
	if ([operatorString isEqualToString:@"$eq"] || [operatorString isEqualToString:@"=="]) {
		return NSEqualToPredicateOperatorType;
	} else if ([operatorString isEqualToString:@"$gt"] || [operatorString isEqualToString:@">"]) {
		return NSGreaterThanPredicateOperatorType;
	} else if ([operatorString isEqualToString:@"$gte"] || [operatorString isEqualToString:@">="]) {
		return NSGreaterThanOrEqualToPredicateOperatorType;
	} else if ([operatorString isEqualToString:@"$lt"] || [operatorString isEqualToString:@"<"]) {
		return NSLessThanPredicateOperatorType;
	} else if ([operatorString isEqualToString:@"$lte"] || [operatorString isEqualToString:@"<="]) {
		return NSLessThanOrEqualToPredicateOperatorType;
	} else if ([operatorString isEqualToString:@"$ne"] || [operatorString isEqualToString:@"!="]) {
		return NSNotEqualToPredicateOperatorType;
	} else if ([operatorString isEqualToString:@"$contains"] || [operatorString isEqualToString:@"CONTAINS[c]"]) {
		return NSContainsPredicateOperatorType;
	} else if ([operatorString isEqualToString:@"$starts_with"] || [operatorString isEqualToString:@"BEGINSWITH[c]"]) {
		return NSBeginsWithPredicateOperatorType;
	} else if ([operatorString isEqualToString:@"$ends_with"] || [operatorString isEqualToString:@"ENDSWITH[c]"]) {
		return NSEndsWithPredicateOperatorType;
	} else {
		ATLogError(@"Unrecognized comparison operator symbol: %@", operatorString);
		*hasError = YES;
		return NSCustomSelectorPredicateOperatorType;
	}
}

@end
