//
//  ATMessage.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 10/6/12.
//  Copyright (c) 2012 Apptentive, Inc. All rights reserved.
//

#import "ATAbstractMessage.h"

#import "ATBackend.h"
#import "ATData.h"
#import "ATJSONSerialization.h"
#import "ATMessageDisplayType.h"
#import "ATMessageSender.h"
#import "NSDictionary+ATAdditions.h"

@implementation ATAbstractMessage

@dynamic pendingMessageID;
@dynamic pendingState;
@dynamic priority;
@dynamic seenByUser;
@dynamic sentByUser;
@dynamic errorOccurred;
@dynamic errorMessageJSON;
@dynamic sender;
@dynamic displayTypes;
@dynamic customData;
@dynamic hidden;

+ (NSObject *)newInstanceWithJSON:(NSDictionary *)json {
	NSAssert(NO, @"Abstract method called.");
	return nil;
}

+ (ATAbstractMessage *)findMessageWithID:(NSString *)apptentiveID {
	ATAbstractMessage *result = nil;
	
	@synchronized(self) {
		NSPredicate *fetchPredicate = [NSPredicate predicateWithFormat:@"(apptentiveID == %@)", apptentiveID];
		NSArray *results = [ATData findEntityNamed:@"ATAbstractMessage" withPredicate:fetchPredicate];
		if (results && [results count]) {
			result = [results objectAtIndex:0];
		}
	}
	return result;
}

+ (ATAbstractMessage *)findMessageWithPendingID:(NSString *)pendingID {
	ATAbstractMessage *result = nil;
	
	@synchronized(self) {
		NSPredicate *fetchPredicate = [NSPredicate predicateWithFormat:@"(pendingMessageID == %@)", pendingID];
		NSArray *results = [ATData findEntityNamed:@"ATAbstractMessage" withPredicate:fetchPredicate];
		if (results && [results count] != 0) {
			result = [results objectAtIndex:0];
		}
	}
	return result;
}

- (void)setup {
	[super setup];
	if (self.pendingMessageID == nil) {
		CFUUIDRef uuidRef = CFUUIDCreate(NULL);
		CFStringRef uuidStringRef = CFUUIDCreateString(NULL, uuidRef);
		
		self.pendingMessageID = [NSString stringWithFormat:@"pending-message:%@", (NSString *)uuidStringRef];
		
		CFRelease(uuidRef), uuidRef = NULL;
		CFRelease(uuidStringRef), uuidStringRef = NULL;
	}
}

- (void)awakeFromInsert {
	[super awakeFromInsert];
	[self setup];
}

- (NSArray *)errorsFromErrorMessage {
	if (self.errorMessageJSON == nil) {
		return nil;
	}
	
	NSError *error = nil;
	NSObject *errorObject = (NSObject *)[ATJSONSerialization JSONObjectWithString:self.errorMessageJSON error:&error];
	
	if (errorObject == nil) {
		ATLogError(@"Error parsing errors: %@", error);
		return nil;
	}
	if ([errorObject isKindOfClass:[NSDictionary class]]) {
		NSDictionary *errorDictionary = (NSDictionary *)errorObject;
		NSObject *errors = [errorDictionary objectForKey:@"errors"];
		if (errors != nil && [errors isKindOfClass:[NSArray class]]) {
			return [[(NSArray *)errors copy] autorelease];
		}
	}
	return nil;
}

- (void)updateWithJSON:(NSDictionary *)json {
	[super updateWithJSON:json];
	
	NSDictionary *senderDict = [json at_safeObjectForKey:@"sender"];
	if (senderDict != nil) {
		ATMessageSender *sender = [ATMessageSender newOrExistingMessageSenderFromJSON:senderDict];
		[self setValue:sender forKey:@"sender"];
		[sender release], sender = nil;
	}
	
	ATMessageDisplayType *messageCenterType = [ATMessageDisplayType messageCenterType];
	ATMessageDisplayType *modalType = [ATMessageDisplayType modalType];
	
	NSNumber *priorityNumber = [json at_safeObjectForKey:@"priority"];
	if (priorityNumber != nil) {
		self.priority = priorityNumber;
	}
	
	NSArray *displayTypes = [json at_safeObjectForKey:@"display"];
	BOOL inserted = NO;
	for (NSString *displayType in displayTypes) {
		if ([displayType isEqualToString:@"modal"]) {
			[self addDisplayTypesObject:modalType];
			inserted = YES;
		} else if ([displayType isEqualToString:@"message center"]) {
			[self addDisplayTypesObject:messageCenterType];
			inserted = YES;
		}
	}
	if (!inserted) {
		[self addDisplayTypesObject:messageCenterType];
	}
}

- (NSDictionary *)apiJSON {
	NSDictionary *parentJSON = [super apiJSON];
	NSMutableDictionary *result = [NSMutableDictionary dictionary];
	if (parentJSON) {
		[result addEntriesFromDictionary:parentJSON];
	}
	if (self.pendingMessageID != nil) {
		result[@"nonce"] = self.pendingMessageID;
	}
	if (self.customData) {
		NSDictionary *customDataDictionary = [self dictionaryForCustomData];
		if (customDataDictionary && customDataDictionary.count) {
			result[@"custom_data"] = customDataDictionary;
		}
	}
	if (self.hidden != nil) {
		result[@"hidden"] = self.hidden;
	}
	
	return result;
}

- (void)setCustomDataValue:(id)value forKey:(NSString *)key {
	NSDictionary *customData = [self dictionaryForCustomData];
	NSMutableDictionary *mutableCustomData = nil;
	if (customData == nil) {
		mutableCustomData = [NSMutableDictionary dictionary];
	} else {
		mutableCustomData = [[customData mutableCopy] autorelease];
	}
	[mutableCustomData setValue:value forKey:key];
	self.customData = [self dataForDictionary:mutableCustomData];
}

- (void)addCustomDataFromDictionary:(NSDictionary *)dictionary {
	NSDictionary *customData = [self dictionaryForCustomData];
	NSMutableDictionary *mutableCustomData = nil;
	if (customData == nil) {
		mutableCustomData = [NSMutableDictionary dictionary];
	} else {
		mutableCustomData = [[customData mutableCopy] autorelease];
	}
	if (dictionary != nil) {
		[mutableCustomData addEntriesFromDictionary:dictionary];
	}
	self.customData = [self dataForDictionary:mutableCustomData];
}

- (NSDictionary *)dictionaryForCustomData {
	if (self.customData == nil) {
		return @{};
	} else {
		NSDictionary *result = nil;
		@try {
			result = [NSKeyedUnarchiver unarchiveObjectWithData:self.customData];
		} @catch (NSException *exception) {
			ATLogError(@"Unable to unarchive event: %@", exception);
		}
		return result;
	}
}

- (NSData *)dataForDictionary:(NSDictionary *)dictionary {
	if (dictionary == nil) {
		return nil;
	} else {
		return [NSKeyedArchiver archivedDataWithRootObject:dictionary];
	}
}

@end
