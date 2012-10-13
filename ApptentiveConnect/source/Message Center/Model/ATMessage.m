//
//  ATMessage.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 10/6/12.
//  Copyright (c) 2012 Apptentive, Inc. All rights reserved.
//

#import "ATMessage.h"
#import "ATBackend.h"
#import "ATMessageDisplayType.h"
#import "ATTextMessage.h"
#import "ATUpgradeRequestMessage.h"

@implementation ATMessage

@dynamic apptentiveID;
@dynamic creationTime;
@dynamic pendingMessageID;
@dynamic pendingState;
@dynamic priority;
@dynamic recipientID;
@dynamic seenByUser;
@dynamic senderID;
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
	} else {
		NSLog(@"Unknown message type");
		return nil;
	}
	
	NSManagedObjectContext *context = [[ATBackend sharedBackend] managedObjectContext];
	
	ATMessageDisplayType *messageCenterType = [ATMessageDisplayType messageCenterType];
	ATMessageDisplayType *modalType = [ATMessageDisplayType modalType];
	
	NSManagedObject *message = [[NSManagedObject alloc] initWithEntity:[NSEntityDescription entityForName:objectName inManagedObjectContext:context] insertIntoManagedObjectContext:context];
	[message setValue:[messageJSON objectForKey:@"id"] forKey:@"apptentiveID"];
	[message setValue:[messageJSON objectForKey:@"sender_id"] forKey:@"senderID"];
	[message setValue:[messageJSON objectForKey:@"recipient_id"] forKey:@"recipientID"];
	
	NSNumber *creationTimestamp = (NSNumber *)[messageJSON objectForKey:@"created_at"];
	[message setValue:creationTimestamp forKey:@"creationTime"];
	
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
	
	if ([objectName isEqualToString:@"ATTextMessage"]) {
		[message setValue:[messageJSON objectForKey:@"body"] forKey:@"body"];
		[message setValue:[messageJSON objectForKey:@"subject"] forKey:@"subject"];
	} else if ([objectName isEqualToString:@"ATUpgradeRequestMessage"]) {
		[message setValue:[messageJSON objectForKey:@"forced"] forKey:@"forced"];
	}
	
	return (ATMessage *)message;
}

+ (ATMessage *)findMessageWithID:(NSString *)apptentiveID {
	NSManagedObjectContext *context = [[ATBackend sharedBackend] managedObjectContext];
	ATMessage *result = nil;
	
	@synchronized(self) {
		NSFetchRequest *fetchTypes = [[NSFetchRequest alloc] initWithEntityName:@"ATMessage"];
		NSPredicate *fetchPredicate = [NSPredicate predicateWithFormat:@"(apptentiveID == %@)", apptentiveID];
		fetchTypes.predicate = fetchPredicate;
		NSError *fetchError = nil;
		NSArray *fetchArray = [context executeFetchRequest:fetchTypes error:&fetchError];
		
		if (fetchArray) {
			for (NSManagedObject *fetchedObject in fetchArray) {
				result = (ATMessage *)fetchedObject;
			}
		}
		[fetchTypes release], fetchTypes = nil;
	}
	return result;
}
@end
