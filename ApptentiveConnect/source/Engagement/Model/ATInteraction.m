//
//  ATInteraction.m
//  ApptentiveConnect
//
//  Created by Peter Kamb on 8/23/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import "ATInteraction.h"
#import "ATEngagementBackend.h"
#import "ATInteractionUsageData.h"
#import "ATUtilities.h"

@implementation ATInteraction

+ (ATInteraction *)interactionWithJSONDictionary:(NSDictionary *)jsonDictionary {
	ATInteraction *interaction = [[ATInteraction alloc] init];
	interaction.identifier = [jsonDictionary objectForKey:@"id"];
	interaction.priority = [[jsonDictionary objectForKey:@"priority"] integerValue];
	interaction.type = [jsonDictionary objectForKey:@"type"];
	interaction.configuration = [jsonDictionary objectForKey:@"configuration"];
	interaction.criteria = [jsonDictionary objectForKey:@"criteria"];
	interaction.version = [jsonDictionary objectForKey:@"version"];
	return [interaction autorelease];
}

- (ATInteractionType)interactionType {
	ATInteractionType interactionType = ATInteractionTypeUnknown;
	if ([self.type isEqualToString:@"UpgradeMessage"]) {
		interactionType = ATInteractionTypeUpgradeMessage;
	} else if ([self.type isEqualToString:@"EnjoymentDialog"]) {
		interactionType = ATInteractionTypeEnjoymentDialog;
	} else if ([self.type isEqualToString:@"RatingDialog"]) {
		interactionType = ATInteractionTypeRatingDialog;
	} else if ([self.type isEqualToString:@"FeedbackDialog"]) {
		interactionType = ATInteractionTypeFeedbackDialog;
	} else if ([self.type isEqualToString:@"MessageCenter"]) {
		interactionType = ATInteractionTypeMessageCenter;
	} else if ([self.type isEqualToString:@"AppStoreRating"]) {
		interactionType = ATInteractionTypeAppStoreRating;
	} else if ([self.type isEqualToString:@"Survey"]) {
		interactionType = ATInteractionTypeSurvey;
	}
	
	return interactionType;
}

- (NSString *)description {	
	NSDictionary *description = @{@"identifier" : self.identifier ?: [NSNull null],
								  @"priority" : [NSNumber numberWithInteger:self.priority] ?: [NSNull null],
								  @"type" : self.type ?: [NSNull null],
								  @"configuration" : self.configuration ?: [NSNull null],
								  @"criteria" : self.criteria ?: [NSNull null],
								  @"version" : self.version ?: [NSNull null]};
	
	return [description description];
}

- (id)initWithCoder:(NSCoder *)coder {
	if ((self = [super init])) {
		self.identifier = [coder decodeObjectForKey:@"identifier"];
		self.priority = [coder decodeIntForKey:@"priority"];
		self.type = [coder decodeObjectForKey:@"type"];
		self.configuration = [coder decodeObjectForKey:@"configuration"];
		self.criteria = [coder decodeObjectForKey:@"criteria"];
		self.version = [coder decodeObjectForKey:@"version"];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
	[coder encodeObject:self.identifier forKey:@"identifier"];
	[coder encodeInteger:self.priority forKey:@"priority"];
	[coder encodeObject:self.type forKey:@"type"];
	[coder encodeObject:self.configuration forKey:@"configuration"];
	[coder encodeObject:self.criteria forKey:@"criteria"];
	[coder encodeObject:self.version forKey:@"version"];
}

- (id)copyWithZone:(NSZone *)zone {
    ATInteraction *copy = [[ATInteraction alloc] init];
	
    if (copy) {
		copy.identifier = self.identifier;
		copy.priority = self.priority;
		copy.type = self.type;
		copy.configuration = self.configuration;
		copy.criteria = self.criteria;
		copy.version = self.version;
    }
	
    return copy;
}

- (BOOL)isValid {
	BOOL isValid = NO;
	
	do { // once
		if (self.interactionType == ATInteractionTypeUnknown) {
			break;
		}
		
		//TODO: Check interaction's version.
		
		if (self.interactionType == ATInteractionTypeUpgradeMessage && ![ATUtilities osVersionGreaterThanOrEqualTo:@"7"]) {
			// Don't show upgrade messages on anything except iOS 7 and above.
			break;
		}
		
		if (![self criteriaAreMet]) {
			break;
		}
		
		isValid = YES;
	} while (NO);
	
	return isValid;
}

- (ATInteractionUsageData *)usageData {
	return [ATInteractionUsageData usageDataForInteraction:self];
}

- (BOOL)criteriaAreMet {
	return [self criteriaAreMetForUsageData:[self usageData]];
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
	NSPredicate *criteriaPredicate = [ATInteraction predicateForInteractionCriteria:self.criteria hasError:&error];
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
			NSPredicate *subPredicate = [ATInteraction predicateForCriteria:criteria operatorExpression:subExpression hasError:hasError];
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
				NSPredicate *criterion = [self predicateForInteractionCriteria:dictionary hasError:hasError];
				[criteria addObject:criterion];
			}
			
			NSPredicate *compoundPredicate = [[[NSCompoundPredicate alloc] initWithType:predicateType subpredicates:criteria] autorelease];
			[subPredicates addObject:compoundPredicate];
		} else {
			// Implicit "==" if object is a string/number
			NSDictionary *equalityDictionary = ([object isKindOfClass:[NSDictionary class]]) ? (NSDictionary *)object : @{@"==" : object};
			NSPredicate *subPredicate = [ATInteraction predicateForCriteria:key operatorExpression:equalityDictionary hasError:hasError];
			if (subPredicate) {
				[subPredicates addObject:subPredicate];
			}
		}
	}
	
	NSPredicate *result = [[[NSCompoundPredicate alloc] initWithType:NSAndPredicateType subpredicates:subPredicates] autorelease];
	return result;
}

- (void)dealloc {
	[_identifier release], _identifier = nil;
	[_type release], _type = nil;
	[_configuration release], _configuration = nil;
	[_criteria release], _criteria = nil;
	[_version release], _version = nil;
	
	[super dealloc];
}

@end
