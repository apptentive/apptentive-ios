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

@implementation ATInteraction

+ (ATInteraction *)interactionWithJSONDictionary:(NSDictionary *)jsonDictionary {
	ATInteraction *interaction = [[ATInteraction alloc] init];
	interaction.identifier = [jsonDictionary objectForKey:@"id"];
	interaction.priority = [[jsonDictionary objectForKey:@"priority"] intValue];
	interaction.type = [jsonDictionary objectForKey:@"type"];
	interaction.configuration = [jsonDictionary objectForKey:@"configuration"];
	interaction.criteria = [jsonDictionary objectForKey:@"criteria"];
	interaction.version = [jsonDictionary objectForKey:@"version"];
	return [interaction autorelease];
}

- (NSString *)description {	
	NSDictionary *description = @{@"identifier" : self.identifier ?: [NSNull null],
								  @"priority" : [NSNumber numberWithInt:self.priority] ?: [NSNull null],
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
	[coder encodeInt:self.priority forKey:@"priority"];
	[coder encodeObject:self.type forKey:@"type"];
	[coder encodeObject:self.configuration forKey:@"configuration"];
	[coder encodeObject:self.criteria forKey:@"criteria"];
	[coder encodeObject:self.version forKey:@"version"];
}

- (ATInteractionUsageData *)usageDataAtCodePoint:(NSString *)codePoint {
	return [ATInteractionUsageData usageDataForInteraction:self atCodePoint:codePoint];
}

- (BOOL)criteriaAreMetForCodePoint:(NSString *)codePoint {
	ATInteractionUsageData *usageDate = [self usageDataAtCodePoint:codePoint];
	return [self criteriaAreMetForUsageData:usageDate];
}

- (BOOL)criteriaAreMetForUsageData:(ATInteractionUsageData *)usageData {
	return [[self criteriaPredicate] evaluateWithObject:usageData];
}

- (NSPredicate *)criteriaPredicate {
	BOOL error = NO;
	NSString *predicateString = [ATInteraction predicateStringForInteractionCriteria:self.criteria hasError:&error];
	
	if (!predicateString || error || [predicateString length] == 0) {
		return nil;
	}
	
	NSPredicate *predicate = [NSPredicate predicateWithFormat:predicateString];
	return predicate;
}

+ (NSString *)predicateStringForInteractionCriteria:(NSDictionary *)interactionCriteria hasError:(BOOL *)hasError {
	NSMutableArray *parts = [NSMutableArray array];
	NSString *joinWith = @" AND ";
	
	for (NSString *key in interactionCriteria) {
		NSObject *object = [interactionCriteria objectForKey:key];
		NSString *escapedKey = [key stringByReplacingOccurrencesOfString:@"." withString:@"_"];
		
		if ([object isKindOfClass:[NSArray class]]) {
			if ([key isEqualToString:@"$and"]) {
				joinWith = @" AND ";
			} else if ([key isEqualToString:@"$or"]) {
				joinWith = @" OR ";
			} else {
				*hasError = YES;
			}
			
			NSMutableArray *criteria = [NSMutableArray array];
			for (NSDictionary *dictionary in (NSArray *)object) {
				NSString *criterion = [self predicateStringForInteractionCriteria:dictionary hasError:hasError];
				[criteria addObject:criterion];
			}
			[parts addObjectsFromArray:criteria];
		}
		else if ([object isKindOfClass:[NSDictionary class]]) {
			NSMutableArray *criteria = [NSMutableArray array];
			for (NSString *equalityKey in (NSDictionary *)object) {
				NSString *equalitySymbol = nil;
				if ([equalityKey isEqualToString:@"$gt"]) {
					equalitySymbol = @">";
				}
				else if ([equalityKey isEqualToString:@"$gte"]) {
					equalitySymbol = @">=";
				}
				else if ([equalityKey isEqualToString:@"$lt"]) {
					equalitySymbol = @"<";
				}
				else if ([equalityKey isEqualToString:@"$lte"]) {
					equalitySymbol = @"<=";
				}
				else if ([equalityKey isEqualToString:@"$ne"]) {
					equalitySymbol = @"!=";
				}
				else {
					*hasError = YES;
				}
				
				NSObject *value = [(NSDictionary *)object objectForKey:equalityKey];
				NSString *valueString = nil;
				if ([value isKindOfClass:[NSString class]]) {
					valueString = [NSString stringWithFormat:@"'%@'", value];
				}
				else if ([value isKindOfClass:[NSNumber class]]) {
					valueString = [NSString stringWithFormat:@"%@", value];
				}
				else {
					*hasError = YES;
				}
				
				NSString *criterion = [NSString stringWithFormat:@"(%@ %@ %@)", escapedKey, equalitySymbol, valueString];
				[criteria addObject:criterion];
			}
			
			[parts addObjectsFromArray:criteria];
		}
		else if ([object isKindOfClass:[NSString class]]) {
			NSString *criterion = [NSString stringWithFormat:@"(%@ == '%@')", escapedKey, (NSString *)object];
			[parts addObject:criterion];
		}
		else if ([object isKindOfClass:[NSNumber class]]) {
			NSString *criterion = [NSString stringWithFormat:@"(%@ == %@)", escapedKey, (NSNumber *)object];
			[parts addObject:criterion];
		}
		else {
			*hasError = YES;
		}
	}
		
	NSString *result = nil;
	if ([parts count] > 1) {
		result = [NSString stringWithFormat:@"(%@)", [parts componentsJoinedByString:joinWith]];
	} else if ([parts count] == 1) {
		result = [NSString stringWithFormat:@"%@", [parts objectAtIndex:0]];
	} else {
		*hasError = YES;
	}
	
	return result;
}

@end
