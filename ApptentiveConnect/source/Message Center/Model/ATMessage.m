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

@implementation ATMessage

@dynamic apptentiveID;
@dynamic creationTime;
@dynamic pendingMessageID;
@dynamic pendingState;
@dynamic priority;
@dynamic seenByUser;
@dynamic sender;
@dynamic recipient;
@dynamic displayTypes;

+ (ATMessage *)newMessageFromJSON:(NSDictionary *)json {
	// Figure out the message type.
	NSDictionary *messageJSON = [json objectForKey:@"message"];
	if (!messageJSON) return nil;
	
	NSString *messageType = [messageJSON objectForKey:@"type"];
	NSString *objectName = nil;
	if ([messageType isEqualToString:@"text_message"]) {
		objectName = @"ATTextMessage";
	} else if ([messageType isEqualToString:@"upgrade_request"]) {
		objectName = @"ATUpgradeRequestMessage";
	} else if ([messageType isEqualToString:@"share_request"]) {
		//!!
		NSLog(@"Unimplimented share request type");
		return nil;
	} else if ([messageType isEqualToString:@"fake"]) {
		objectName = @"ATFakeMessage";
	} else {
		NSLog(@"Unknown message type");
		return nil;
	}
	
	ATMessageDisplayType *messageCenterType = [ATMessageDisplayType messageCenterType];
	ATMessageDisplayType *modalType = [ATMessageDisplayType modalType];
	
	NSManagedObject *message = [ATData newEntityNamed:objectName];
	
	[(ATMessage *)message updateWithJSON:messageJSON];
	
	NSObject *creationDate = [messageJSON objectForKey:@"created_at"];
	if ([creationDate isKindOfClass:[NSNumber class]]) {
		NSNumber *creationTimestamp = (NSNumber *)[messageJSON objectForKey:@"created_at"];
		[message setValue:creationTimestamp forKey:@"creationTime"];
	} else if ([creationDate isKindOfClass:[NSDate class]]) {
		NSDate *creationDate = (NSDate *)[messageJSON objectForKey:@"created_at"];
		NSTimeInterval t = [creationDate timeIntervalSince1970];
		NSNumber *creationTimestamp = [NSNumber numberWithFloat:t];
		[message setValue:creationTimestamp forKey:@"creationTime"];
	}
	
	[message setValue:[messageJSON objectForKey:@"priority"] forKey:@"priority"];
	
	NSArray *displayTypes = [messageJSON objectForKey:@"display"];
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
		[message setValue:[messageJSON objectForKey:@"body"] forKey:@"body"];
		[message setValue:[messageJSON objectForKey:@"subject"] forKey:@"subject"];
	} else if ([objectName isEqualToString:@"ATUpgradeRequestMessage"]) {
		[message setValue:[messageJSON objectForKey:@"forced"] forKey:@"forced"];
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

- (void)updateWithJSON:(NSDictionary *)messageJSON {
	NSDictionary *senderDict = [messageJSON objectForKey:@"sender"];
	ATMessageSender *sender = [ATMessageSender newOrExistingMessageSenderFromJSON:senderDict];
	NSDictionary *recipientDict = [messageJSON objectForKey:@"recipient"];
	ATMessageSender *recipient = [ATMessageSender newOrExistingMessageSenderFromJSON:recipientDict];
	
	[self setValue:[messageJSON objectForKey:@"id"] forKey:@"apptentiveID"];
	[self setValue:sender forKey:@"sender"];
	[self setValue:recipient forKey:@"recipient"];
}
@end
