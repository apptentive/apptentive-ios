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
#import "ATFakeMessage.h"
#import "ATMessageDisplayType.h"
#import "ATMessageSender.h"
#import "ATTextMessage.h"
#import "ATUpgradeRequestMessage.h"
#import "NSDictionary+ATAdditions.h"

@implementation ATMessage

@dynamic apptentiveID;
@dynamic clientCreationTime;
@dynamic clientCreationTimezone;
@dynamic clientCreationUTCOffset;
@dynamic creationTime;
@dynamic pendingMessageID;
@dynamic pendingState;
@dynamic priority;
@dynamic seenByUser;
@dynamic sentByUser;
@dynamic sender;
@dynamic displayTypes;

+ (ATMessage *)newMessageFromJSON:(NSDictionary *)json {
	NSString *messageType = [json at_safeObjectForKey:@"type"];
	NSString *objectName = nil;
	if ([messageType isEqualToString:@"TextMessage"]) {
		objectName = @"ATTextMessage";
//	}
	//else if ([messageType isEqualToString:@"upgrade_request"]) {
	//	objectName = @"ATUpgradeRequestMessage";
	//} else if ([messageType isEqualToString:@"share_request"]) {
		//!!
	//	NSLog(@"Unimplimented share request type");
	//	return nil;
	} else if ([messageType isEqualToString:@"fake"]) {
		objectName = @"ATFakeMessage";
	} else {
		NSLog(@"Unknown message type");
		return nil;
	}
	
	ATMessageDisplayType *messageCenterType = [ATMessageDisplayType messageCenterType];
	ATMessageDisplayType *modalType = [ATMessageDisplayType modalType];
	
	NSManagedObject *message = [ATData newEntityNamed:objectName];
	
	[(ATMessage *)message updateWithJSON:json];
	
	NSObject *creationDateObject = [json at_safeObjectForKey:@"created_at"];
	if ([creationDateObject isKindOfClass:[NSNumber class]]) {
		NSTimeInterval creationTimestamp = [ATMessage timeIntervalForServerTime:(NSNumber *)creationDateObject];
		[message setValue:@(creationTimestamp) forKey:@"creationTime"];
	} else if ([creationDateObject isKindOfClass:[NSDate class]]) {
		NSDate *creationDate = (NSDate *)creationDateObject;
		NSTimeInterval t = [creationDate timeIntervalSince1970];
		NSNumber *creationTimestamp = [NSNumber numberWithFloat:t];
		[message setValue:creationTimestamp forKey:@"creationTime"];
	}
	
	[message setValue:[json at_safeObjectForKey:@"priority"] forKey:@"priority"];
	
	NSArray *displayTypes = [json at_safeObjectForKey:@"display"];
	BOOL inserted = NO;
	for (NSString *displayType in displayTypes) {
		if ([displayType isEqualToString:@"modal"]) {
			[(ATMessage *)message addDisplayTypesObject:modalType];
			inserted = YES;
		} else if ([displayType isEqualToString:@"message center"]) {
			[(ATMessage *)message addDisplayTypesObject:messageCenterType];
			inserted = YES;
		}
	}
	if (!inserted) {
		[(ATMessage *)message addDisplayTypesObject:messageCenterType];
	}
	
	if ([objectName isEqualToString:@"ATTextMessage"] || [objectName isEqualToString:@"ATFakeMessage"]) {
		[message setValue:[json at_safeObjectForKey:@"body"] forKey:@"body"];
	} else if ([objectName isEqualToString:@"ATUpgradeRequestMessage"]) {
		[message setValue:[json at_safeObjectForKey:@"forced"] forKey:@"forced"];
	}
	
	return (ATMessage *)message;
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

#warning No Sender or Recipient anymore
- (void)updateWithJSON:(NSDictionary *)messageJSON {
	NSDictionary *senderDict = [messageJSON at_safeObjectForKey:@"sender"];
	ATMessageSender *sender = [ATMessageSender newOrExistingMessageSenderFromJSON:senderDict];
	[self setValue:sender forKey:@"sender"];
	
	if ([messageJSON at_safeObjectForKey:@"created_at"]) {
		NSTimeInterval timestamp = [ATMessage timeIntervalForServerTime:[messageJSON at_safeObjectForKey:@"created_at"]];
		self.creationTime = @(timestamp);
	}
	[self setValue:[messageJSON at_safeObjectForKey:@"id"] forKey:@"apptentiveID"];
	[sender release], sender = nil;
}

+ (NSTimeInterval)timeIntervalForServerTime:(NSNumber *)timestamp {
	long long serverTimestamp = [timestamp longLongValue];
	NSTimeInterval clientTimestamp = ((double)serverTimestamp)/1000.0;
	return clientTimestamp;
}

+ (NSNumber *)serverFormatForTimeInterval:(NSTimeInterval)timestamp {
	return @((long long)(timestamp * 1000));
}
@end
