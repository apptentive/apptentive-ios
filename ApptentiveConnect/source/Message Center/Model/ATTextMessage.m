//
//  ATTextMessage.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 10/6/12.
//  Copyright (c) 2012 Apptentive, Inc. All rights reserved.
//

#import "ATTextMessage.h"

#import "ATBackend.h"
#import "ATData.h"

@implementation ATTextMessage

@dynamic body;
@dynamic subject;

+ (ATTextMessage *)findMessageWithPendingID:(NSString *)pendingID {
	ATTextMessage *result = nil;
	
	@synchronized(self) {
		NSPredicate *fetchPredicate = [NSPredicate predicateWithFormat:@"(pendingMessageID == %@)", pendingID];
		NSArray *results = [ATData findEntityNamed:@"ATTextMessage" withPredicate:fetchPredicate];
		if (results && [results count] != 0) {
			result = [results objectAtIndex:0];
		}
	}
	return result;
}

+ (ATTextMessage *)createMessageWithPendingMessage:(ATPendingMessage *)pendingMessage {
	NSManagedObjectContext *context = [[ATBackend sharedBackend] managedObjectContext];
	
	ATTextMessage *message = [ATTextMessage findMessageWithPendingID:pendingMessage.pendingMessageID];
	if (!message) {
		message = [[[ATTextMessage alloc] initWithEntity:[NSEntityDescription entityForName:@"ATTextMessage" inManagedObjectContext:context] insertIntoManagedObjectContext:context] autorelease];
		message.pendingMessageID = pendingMessage.pendingMessageID;
		message.pendingState = [NSNumber numberWithInt:ATPendingMessageStateComposing];
		message.body = pendingMessage.body;
		message.creationTime = [NSNumber numberWithDouble:pendingMessage.creationTime];
		[context save:nil];
	}
	return message;
}

+ (void)clearComposingMessages {
	@synchronized(self) {
		NSPredicate *fetchPredicate = [NSPredicate predicateWithFormat:@"(pendingState == %d)", ATPendingMessageStateComposing];
		[ATData removeEntitiesNamed:@"ATTextMessage" withPredicate:fetchPredicate];
	}
}
@end
