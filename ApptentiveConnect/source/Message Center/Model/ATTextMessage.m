//
//  ATTextMessage.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 10/6/12.
//  Copyright (c) 2012 Apptentive, Inc. All rights reserved.
//

#import "ATTextMessage.h"

#import "ATBackend.h"

@implementation ATTextMessage

@dynamic body;
@dynamic subject;

+ (ATTextMessage *)findMessageWithPendingID:(NSString *)pendingID {
	NSManagedObjectContext *context = [[ATBackend sharedBackend] managedObjectContext];
	ATTextMessage *result = nil;
	
	@synchronized(self) {
		NSFetchRequest *fetchTypes = [[NSFetchRequest alloc] initWithEntityName:@"ATTextMessage"];
		NSPredicate *fetchPredicate = [NSPredicate predicateWithFormat:@"(pendingMessageID == %@)", pendingID];
		fetchTypes.predicate = fetchPredicate;
		NSError *fetchError = nil;
		NSArray *fetchArray = [context executeFetchRequest:fetchTypes error:&fetchError];
		
		if (fetchArray) {
			for (NSManagedObject *fetchedObject in fetchArray) {
				result = (ATTextMessage *)fetchedObject;
			}
		}
	}
	return result;
}

+ (ATTextMessage *)createMessageWithPendingMessage:(ATPendingMessage *)pendingMessage {
	NSManagedObjectContext *context = [[ATBackend sharedBackend] managedObjectContext];
	
	ATTextMessage *message = [ATTextMessage findMessageWithPendingID:pendingMessage.pendingMessageID];
	if (!message) {
		message = [[ATTextMessage alloc] initWithEntity:[NSEntityDescription entityForName:@"ATTextMessage" inManagedObjectContext:context] insertIntoManagedObjectContext:context];
		message.pendingMessageID = pendingMessage.pendingMessageID;
		message.pendingState = [NSNumber numberWithInt:ATPendingMessageStateComposing];
		message.body = pendingMessage.body;
		message.creationTime = [NSNumber numberWithDouble:pendingMessage.creationTime];
		[context save:nil];
	}
	return message;
}

+ (void)clearComposingMessages {
	NSManagedObjectContext *context = [[ATBackend sharedBackend] managedObjectContext];
	
	@synchronized(self) {
		NSFetchRequest *fetchTypes = [[NSFetchRequest alloc] initWithEntityName:@"ATTextMessage"];
		NSPredicate *fetchPredicate = [NSPredicate predicateWithFormat:@"(pendingState == %d)", ATPendingMessageStateComposing];
		fetchTypes.predicate = fetchPredicate;
		NSError *fetchError = nil;
		NSArray *fetchArray = [context executeFetchRequest:fetchTypes error:&fetchError];
		
		if (fetchArray) {
			for (NSManagedObject *fetchedObject in fetchArray) {
				[context deleteObject:fetchedObject];
			}
			[context save:nil];
		}
	}
}
@end
