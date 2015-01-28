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
	ATInteractionInvocation *invocation = [[[ATInteractionInvocation alloc] init] autorelease];
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

+ (NSPredicate *)predicateForCriteria:(NSString *)criteria operatorExpression:(NSDictionary *)operatorExpression hasError:(BOOL *)hasError {
	NSMutableArray *predicates = [NSMutableArray array];
	
	for (NSString *operator in operatorExpression) {
		NSObject *value = operatorExpression[operator];
		if ([operator isEqualToString:@"$not"]) {
			if (![value isKindOfClass:[NSDictionary class]]) {
				ATLogError(@"Expected operator of $not expression to be dictionary.");
				*hasError = YES;
				break;
			}
			NSDictionary *subExpression = (NSDictionary *)value;
			NSPredicate *subPredicate = [ATInteractionInvocation predicateForCriteria:criteria operatorExpression:subExpression hasError:hasError];
			if (!subPredicate || *hasError) {
				break;
			}
			NSCompoundPredicate *predicate = [[NSCompoundPredicate alloc] initWithType:NSNotPredicateType subpredicates:@[subPredicate]];
			[predicates addObject:predicate];
			[predicate release], predicate = nil;
		} else {
			NSString *equalitySymbol = nil;
			BOOL isExists = NO;
			if ([operator isEqualToString:@"=="]) {
				equalitySymbol = @"==";
			} else if ([operator isEqualToString:@"$gt"]) {
				equalitySymbol = @">";
			} else if ([operator isEqualToString:@"$gte"]) {
				equalitySymbol = @">=";
			} else if ([operator isEqualToString:@"$lt"]) {
				equalitySymbol = @"<";
			} else if ([operator isEqualToString:@"$lte"]) {
				equalitySymbol = @"<=";
			} else if ([operator isEqualToString:@"$ne"]) {
				equalitySymbol = @"!=";
			} else if ([operator isEqualToString:@"$contains"]) {
				equalitySymbol = @"CONTAINS[c]";
			} else if ([operator isEqualToString:@"$starts_with"]) {
				equalitySymbol = @"BEGINSWITH[c]";
			} else if ([operator isEqualToString:@"$ends_with"]) {
				equalitySymbol = @"ENDSWITH[c]";
			} else if ([operator isEqualToString:@"$exists"]) {
				isExists = YES;
			} else {
				ATLogError(@"Unrecognized operator symbol: %@", operator);
				*hasError = YES;
				break;
			}
			
			if (isExists) {
				if (![value isKindOfClass:[NSNumber class]]) {
					ATLogError(@"Given non-bool argument to $exists.");
					*hasError = YES;
					break;
				}
				BOOL operandValue = [(NSNumber *)value boolValue];
				if (operandValue) {
					equalitySymbol = @"!=";
				} else {
					equalitySymbol = @"==";
				}
				NSString *placeholder = [[@"(%K " stringByAppendingString:equalitySymbol] stringByAppendingString:@" nil)"];
				NSPredicate *predicate = [NSPredicate predicateWithFormat:placeholder, criteria];
				[predicates addObject:predicate];
			} else {
				NSString *placeholder = [[@"(%K " stringByAppendingString:equalitySymbol] stringByAppendingString:@" %@)"];
				NSPredicate *predicate = [NSCompoundPredicate predicateWithFormat:placeholder argumentArray:@[criteria, value]];
				[predicates addObject:predicate];
			}
			
			// Save the codepoint/interaction, to later be used in predicate evaluation object.
			if ([criteria hasPrefix:@"code_point/"]) {
				NSArray *components = [criteria componentsSeparatedByString:@"/"];
				if (components.count > 1) {
					NSString *codePoint = [components objectAtIndex:1];
					[[ATEngagementBackend sharedBackend] codePointWasSeen:codePoint];
				}
			}
			else if ([criteria hasPrefix:@"interactions/"]) {
				NSArray *components = [criteria componentsSeparatedByString:@"/"];
				if (components.count > 1) {
					NSString *interactionID = [components objectAtIndex:1];
					[[ATEngagementBackend sharedBackend] interactionWasSeen:interactionID];
				}
				
			}
		}
	}
	
	
	if (*hasError) {
		return nil;
	} else {
		NSCompoundPredicate *result = [[NSCompoundPredicate alloc] initWithType:NSAndPredicateType subpredicates:predicates];
		if (!result) {
			*hasError = YES;
		}
		return [result autorelease];
	}
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
			
			NSPredicate *compoundPredicate = [[[NSCompoundPredicate alloc] initWithType:predicateType subpredicates:criteria] autorelease];
			[subPredicates addObject:compoundPredicate];
		} else {
			// Implicit "==" if object is a string/number
			NSDictionary *equalityDictionary = ([object isKindOfClass:[NSDictionary class]]) ? (NSDictionary *)object : @{@"==" : object};
			NSPredicate *subPredicate = [ATInteractionInvocation predicateForCriteria:key operatorExpression:equalityDictionary hasError:hasError];
			if (subPredicate) {
				[subPredicates addObject:subPredicate];
			}
		}
	}
	
	NSPredicate *result = [[[NSCompoundPredicate alloc] initWithType:NSAndPredicateType subpredicates:subPredicates] autorelease];
	return result;
}

@end
