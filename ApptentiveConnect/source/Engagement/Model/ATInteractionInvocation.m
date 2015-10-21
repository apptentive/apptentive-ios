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
	BOOL error = NO;
	NSPredicate *criteriaPredicate = [ATInteractionInvocation predicateForInteractionCriteria:self.criteria hasError:&error];
	if (!criteriaPredicate || error) {
		return nil;
	}
	
	return criteriaPredicate;
}

+ (NSPredicate *)predicateForKeyPath:(NSString *)keyPath operatorsAndValues:(NSDictionary *)operatorsAndValues hasError:(BOOL *)hasError {
	NSMutableArray *predicates = [NSMutableArray array];
	
	for (NSString *operator in operatorsAndValues) {
		NSString *predicateOperator = [self predicateOperatorFromComparisonOperator:operator];
		
		NSPredicate *predicate = [self predicateForKeyPath:keyPath predicateOperator:predicateOperator value:operatorsAndValues[operator]];
		if (predicate) {
			[predicates addObject:predicate];
		} else {
			*hasError = YES;
			break;
		}
	}
	
	if (*hasError) {
		return nil;
	} else {
		NSCompoundPredicate *result = [[NSCompoundPredicate alloc] initWithType:NSAndPredicateType subpredicates:predicates];
		if (!result) {
			*hasError = YES;
		}
		return result;
	}
}

+ (NSPredicate *)predicateForKeyPath:(NSString *)keyPath predicateOperator:(NSString *)predicateOperator value:(NSObject *)value {
	NSPredicate *predicate = nil;
	
	if ([predicateOperator isEqualToString:@"$exists"]) {
		if ([value isKindOfClass:[NSNumber class]]) {
			NSString *predicateFormatString = [[@"(%K " stringByAppendingString:([(NSNumber *)value boolValue] ? @"!=" : @"==")] stringByAppendingString:@" nil)"];
			predicate = [NSPredicate predicateWithFormat:predicateFormatString, keyPath];
		} else {
			ATLogError(@"$exists operator with a non-bool value");
		}
	} else if ([value isKindOfClass:[NSString class]] || [value isKindOfClass:[NSNumber class]]) {
		NSString *predicateFormatString = [[@"(%K " stringByAppendingString:predicateOperator] stringByAppendingString:@" %@)"];
		predicate = [NSCompoundPredicate predicateWithFormat:predicateFormatString argumentArray:@[keyPath, value]];
	} else if ([value isKindOfClass:[NSDictionary class]]) {
		predicate = [NSCompoundPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
			return [self compareComplexObject:evaluatedObject predicateOperator:predicateOperator withComplexObject:value];
		}];
	}
	
	return predicate;
}

+ (NSComparisonPredicate *)predicateWithLeftKeyPath:(NSString *)leftKeyPath rightValue:(nullable id)rightValue operatorType:(NSPredicateOperatorType)operatorType {
	NSExpression *leftExpression = [NSExpression expressionForKeyPath:leftKeyPath];
	NSExpression *rightExpression = [NSExpression expressionForConstantValue:rightValue];
	
	return [self predicateWithLeftExpression:leftExpression rightExpression:rightExpression operatorType:operatorType];
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
			options = NSNormalizedPredicateOption;
			break;
	}
	
	NSComparisonPredicate *predicate = [NSComparisonPredicate predicateWithLeftExpression:leftExpression
																		  rightExpression:rightExpression
																				 modifier:NSDirectPredicateModifier
																					 type:operatorType
																				  options:NSCaseInsensitivePredicateOption];
	return predicate;
}

+ (BOOL)compareComplexObject:(NSDictionary *)leftComplexObject predicateOperator:(NSString *)predicateOperator withComplexObject:(NSDictionary *)rightComplexObject {
	
	NSString *type = leftComplexObject[@"_type"];
	NSString *rightType = rightComplexObject[@"_type"];
	if (![type isEqualToString:rightType]) {
#warning TODO
		ATLogError(@"Criteria Comlex Types must have the same type!");
	}
	
	NSObject *leftValue;
	NSObject *rightValue;
	
	if ([type isEqualToString:@"version"]) {
		NSString *leftVersion = leftComplexObject[@"version"];
		NSString *rightVersion = rightComplexObject[@"version"];
		
		NSComparisonResult result = [self compareVersion:leftVersion withVersion:rightVersion];
		
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
	
	NSString *predicateFormatString = [[@"(%@ " stringByAppendingString:predicateOperator] stringByAppendingString:@" %@)"];
	NSPredicate *predicate = [NSCompoundPredicate predicateWithFormat:predicateFormatString argumentArray:@[leftValue, rightValue]];
	
	return [predicate evaluateWithObject:nil];
}

+ (NSPredicate *)predicateForInteractionCriteria:(NSDictionary *)interactionCriteria hasError:(BOOL *)hasError {
	NSMutableArray *subPredicates = [NSMutableArray array];
	
	for (NSString *key in interactionCriteria) {
		NSObject *object = [interactionCriteria objectForKey:key];
		
		if ([object isKindOfClass:[NSArray class]]) {
			NSCompoundPredicateType predicateType = NSAndPredicateType;
			if ([key isEqualToString:@"$and"]) {
				predicateType = NSAndPredicateType;
			} else if ([key isEqualToString:@"$or"]) {
				predicateType = NSOrPredicateType;
			} else {
				*hasError = YES;
			}
			
			NSMutableArray *criteria = [NSMutableArray array];
			for (NSDictionary *dictionary in (NSArray *)object) {
				NSPredicate *criterion = [ATInteractionInvocation predicateForInteractionCriteria:dictionary hasError:hasError];
				[criteria addObject:criterion];
			}
			
			NSPredicate *compoundPredicate = [[NSCompoundPredicate alloc] initWithType:predicateType subpredicates:criteria];
			[subPredicates addObject:compoundPredicate];
		} else {
			// Implicit "==" if object is a string/number
			NSDictionary *equalityDictionary = ([object isKindOfClass:[NSDictionary class]]) ? (NSDictionary *)object : @{@"==" : object};
			NSPredicate *subPredicate = [ATInteractionInvocation predicateForKeyPath:key operatorsAndValues:equalityDictionary hasError:hasError];
			if (subPredicate) {
				[subPredicates addObject:subPredicate];
			}
		}
	}
	
	NSPredicate *result = [[NSCompoundPredicate alloc] initWithType:NSAndPredicateType subpredicates:subPredicates];
	return result;
}

+ (NSPredicateOperatorType)predicateOperatorTypeFromString:(NSString *)operatorString {
	if ([operatorString isEqualToString:@"=="]) {
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
		return NSCustomSelectorPredicateOperatorType;
	}
}

+ (NSComparisonResult)compareVersion:(NSString *)leftVersion withVersion:(NSString *)rightVersion {
	NSArray *leftComponents = [leftVersion componentsSeparatedByString:@"."];
	NSArray *rightComponents = [rightVersion componentsSeparatedByString:@"."];
	
	NSUInteger minIndex = MIN(leftComponents.count, rightComponents.count);
	
	for (int i = 0; i < minIndex; i++) {
		NSInteger leftInteger = [leftComponents[i] integerValue];
		NSInteger rightInteger = [rightComponents[i] integerValue];
		
		if (leftInteger < rightInteger) {
			return NSOrderedAscending;
		}
		
		if (leftInteger > rightInteger) {
			return NSOrderedDescending;
		}
	}
	
	if (leftComponents.count < rightComponents.count) {
		return NSOrderedAscending;
	}
	
	if (leftComponents.count > rightComponents.count) {
		return NSOrderedDescending;
	}
	
	return NSOrderedSame;
}

@end
