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
	NSString *messageType = [json objectForKey:@"type"];
	NSString *objectName = nil;
	if ([messageType isEqualToString:@"Message"]) {
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
	
	NSObject *creationDateObject = [json objectForKey:@"created_at"];
	if ([creationDateObject isKindOfClass:[NSNumber class]]) {
		NSNumber *creationTimestamp = (NSNumber *)creationDateObject;
		[message setValue:creationTimestamp forKey:@"creationTime"];
	} else if ([creationDateObject isKindOfClass:[NSDate class]]) {
		NSDate *creationDate = (NSDate *)creationDateObject;
		NSTimeInterval t = [creationDate timeIntervalSince1970];
		NSNumber *creationTimestamp = [NSNumber numberWithFloat:t];
		[message setValue:creationTimestamp forKey:@"creationTime"];
	}
	
	[message setValue:[json objectForKey:@"priority"] forKey:@"priority"];
	
	NSArray *displayTypes = [json objectForKey:@"display"];
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
		[message setValue:[json objectForKey:@"body"] forKey:@"body"];
	} else if ([objectName isEqualToString:@"ATUpgradeRequestMessage"]) {
		[message setValue:[json objectForKey:@"forced"] forKey:@"forced"];
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
