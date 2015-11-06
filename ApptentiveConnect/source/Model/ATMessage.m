//
//  ATMessage.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 10/6/12.
//  Copyright (c) 2012 Apptentive, Inc. All rights reserved.
//

#import "ATMessage.h"
#import "ATBackend.h"
#import "ATData.h"
#import "ATJSONSerialization.h"
#import "ATMessageSender.h"
#import "NSDictionary+ATAdditions.h"
#import "ATMessageCenterInteraction.h"

NSString *const ATInteractionMessageCenterEventLabelRead = @"read";

@implementation ATMessage

@dynamic pendingMessageID;
@dynamic pendingState;
@dynamic priority;
@dynamic seenByUser;
@dynamic sentByUser;
@dynamic errorOccurred;
@dynamic errorMessageJSON;
@dynamic sender;
@dynamic customData;
@dynamic hidden;
@dynamic automated;
@dynamic title;
@dynamic body;
@dynamic attachments;

+ (void)clearComposingMessages {
	@synchronized(self) {
		NSPredicate *fetchPredicate = [NSPredicate predicateWithFormat:@"(pendingState == %d)", ATPendingMessageStateComposing];
		[ATData removeEntitiesNamed:@"ATMessage" withPredicate:fetchPredicate];
	}
}

	NSManagedObjectContext *context = [[ATBackend sharedBackend] managedObjectContext];
+ (instancetype)newInstanceWithJSON:(NSDictionary *)json {
	ATMessage *message = nil;
	NSString *apptentiveID = [json at_safeObjectForKey:@"id"];

	if (apptentiveID) {
		message = [self findMessageWithID:apptentiveID];
	}
	if (message == nil) {
		message = [[ATMessage alloc] initWithEntity:[NSEntityDescription entityForName:@"ATMessage" inManagedObjectContext:context] insertIntoManagedObjectContext:context];
	}
	[message updateWithJSON:json];

	// If server creation time is set, overwrite client creation time.
	if (![message isCreationTimeEmpty]) {
		message.clientCreationTime = message.creationTime;
	}

	return message;
}

+ (ATMessage *)findMessageWithID:(NSString *)apptentiveID {
	ATMessage *result = nil;
	
	@synchronized(self) {
		NSPredicate *fetchPredicate = [NSPredicate predicateWithFormat:@"(apptentiveID == %@)", apptentiveID];
		NSArray *results = [ATData findEntityNamed:@"ATMessage" withPredicate:fetchPredicate];
		if (results && [results count]) {
			result = [results objectAtIndex:0];
		}
	}
	return result;
}

+ (ATMessage *)findMessageWithPendingID:(NSString *)pendingID {
	ATMessage *result = nil;
	
	@synchronized(self) {
		NSPredicate *fetchPredicate = [NSPredicate predicateWithFormat:@"(pendingMessageID == %@)", pendingID];
		NSArray *results = [ATData findEntityNamed:@"ATMessage" withPredicate:fetchPredicate];
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
		
		self.pendingMessageID = [NSString stringWithFormat:@"pending-message:%@", (__bridge NSString *)uuidStringRef];
		
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
			return [(NSArray *)errors copy];
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
		sender = nil;
	}

	NSNumber *priorityNumber = [json at_safeObjectForKey:@"priority"];
	if (priorityNumber != nil) {
		self.priority = priorityNumber;
	}

	NSString *tmpBody = [json at_safeObjectForKey:@"body"];
	if (tmpBody) {
		self.body = tmpBody;
	}
}

- (NSDictionary *)apiJSON {
	NSDictionary *parentJSON = [super apiJSON];
	NSMutableDictionary *result = [NSMutableDictionary dictionary];
	if (parentJSON) {
		[result addEntriesFromDictionary:parentJSON];
	}
	if (self.body) {
		result[@"body"] = self.body;
	}
	if (self.automated.boolValue) {
		result[@"automated"] = @YES;
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
		mutableCustomData = [customData mutableCopy];
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
		mutableCustomData = [customData mutableCopy];
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

- (NSNumber *)creationTimeForSections {
	BOOL distantFutureCreationTime = (self.creationTime.doubleValue > self.clientCreationTime.doubleValue + 365 * 24 * 60 * 60);
	
	return distantFutureCreationTime ? self.clientCreationTime : self.creationTime;
}

- (void)markAsRead {
	if (![self.seenByUser boolValue]) {
		self.seenByUser = @YES;
		if (self.apptentiveID && ![self.sentByUser boolValue]) {
			NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
			
			if (self.apptentiveID) {
				[userInfo setObject:self.apptentiveID forKey:@"message_id"];
			}

			[userInfo setObject:@"CompoundMessage" forKey:@"message_type"];

			[[ATMessageCenterInteraction interactionForInvokingMessageEvents] engage:ATInteractionMessageCenterEventLabelRead fromViewController:nil userInfo:userInfo];
		}
		
		[ATData save];
	}
}

@end
