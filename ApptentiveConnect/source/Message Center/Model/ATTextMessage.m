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
#import "NSDictionary+ATAdditions.h"

@implementation ATTextMessage

@dynamic body;
@dynamic subject;


+ (ATTextMessage *)createMessageWithPendingMessage:(ATPendingMessage *)pendingMessage {
	NSManagedObjectContext *context = [[ATBackend sharedBackend] managedObjectContext];
	
	ATTextMessage *message = (ATTextMessage *)[ATTextMessage findMessageWithPendingID:pendingMessage.pendingMessageID];
	if (!message) {
		message = [[[ATTextMessage alloc] initWithEntity:[NSEntityDescription entityForName:@"ATTextMessage" inManagedObjectContext:context] insertIntoManagedObjectContext:context] autorelease];
		message.pendingMessageID = pendingMessage.pendingMessageID;
		message.pendingState = [NSNumber numberWithInt:ATPendingMessageStateComposing];
		message.body = pendingMessage.body;
		message.creationTime = [NSNumber numberWithDouble:pendingMessage.creationTime];
		message.clientCreationTime = message.creationTime;
		[context save:nil];
	}
	return message;
}

+ (NSObject *)newInstanceWithJSON:(NSDictionary *)json {
	NSManagedObjectContext *context = [[ATBackend sharedBackend] managedObjectContext];
	ATTextMessage *message = nil;
	NSString *apptentiveID = [json at_safeObjectForKey:@"id"];
	
	if (apptentiveID) {
		message = [(ATTextMessage *)[ATMessage findMessageWithID:apptentiveID] retain];
	}
	if (message == nil) {
		message = [[ATTextMessage alloc] initWithEntity:[NSEntityDescription entityForName:@"ATTextMessage" inManagedObjectContext:context] insertIntoManagedObjectContext:context];
	}
	[message updateWithJSON:json];
	return message;
}

- (void)updateWithJSON:(NSDictionary *)json {
	[super updateWithJSON:json];
	
	NSString *tmpBody = [json at_safeObjectForKey:@"body"];
	if (tmpBody) {
		self.body = tmpBody;
	}
}

- (NSDictionary *)apiJSON {
	NSDictionary *messageJSON = [super apiJSON];
	NSMutableDictionary *result = [NSMutableDictionary dictionaryWithDictionary:messageJSON];
	
	if (self.body) {
		result[@"body"] = self.body;
	}
	
	return result;
}

+ (void)clearComposingMessages {
	@synchronized(self) {
		NSPredicate *fetchPredicate = [NSPredicate predicateWithFormat:@"(pendingState == %d)", ATPendingMessageStateComposing];
		[ATData removeEntitiesNamed:@"ATTextMessage" withPredicate:fetchPredicate];
	}
}
@end
