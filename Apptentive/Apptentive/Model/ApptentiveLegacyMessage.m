//
//  ApptentiveLegacyMessage.m
//  Apptentive
//
//  Created by Andrew Wooster on 10/6/12.
//  Copyright (c) 2012 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveLegacyMessage.h"
#import "Apptentive_Private.h"
#import "ApptentiveBackend.h"
#import "ApptentiveLegacyMessageSender.h"
#import "ApptentiveLegacyFileAttachment.h"
#import "ApptentiveSerialRequest.h"
#import "ApptentiveAttachment.h"
#import "ApptentiveMessage.h"
#import "ApptentiveMessagePayload.h"


@implementation ApptentiveLegacyMessage

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

+ (void)enqueueUnsentMessagesInContext:(NSManagedObjectContext *)context forConversation:(ApptentiveConversation *)conversation {
	ApptentiveAssertNotNil(context, @"Context is nil");
	ApptentiveAssertNotNil(conversation, @"Conversation is nil");

	NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"ATMessage"];
	request.predicate = [NSPredicate predicateWithFormat:@"(pendingState == %d) || (pendingState == %d)", ATPendingMessageStateSending, ATPendingMessageStateError];

	NSError *error;
	NSArray *unsentMessages = [context executeFetchRequest:request error:&error];

	if (unsentMessages == nil) {
		ApptentiveLogError(@"Unable to retrieve unsent messages: %@", error);
		return;
	}

	for (ApptentiveLegacyMessage *legacyMessage in unsentMessages) {
		NSMutableArray *attachments = [NSMutableArray arrayWithCapacity:legacyMessage.attachments.count];
		for (ApptentiveLegacyFileAttachment *legacyAttachment in legacyMessage.attachments) {
			ApptentiveAttachment *attachment = [[ApptentiveAttachment alloc] initWithPath:legacyAttachment.localPath contentType:legacyAttachment.mimeType name:legacyAttachment.name];

			if (attachment) {
				[attachments addObject:attachment];
			}
		}

		NSDictionary *customData = @{};
		if (legacyMessage.customData) {
			customData = [NSKeyedUnarchiver unarchiveObjectWithData:legacyMessage.customData];
		};

		ApptentiveMessage *message = [[ApptentiveMessage alloc] initWithBody:legacyMessage.body attachments:attachments senderIdentifier:legacyMessage.sender.apptentiveID automated:legacyMessage.automated.boolValue customData:customData];

		ApptentiveMessagePayload *payload = [[ApptentiveMessagePayload alloc] initWithMessage:message];
		ApptentiveAssertNotNil(payload, @"Failed to create a message payload");

		if (payload != nil) {
			[ApptentiveSerialRequest enqueuePayload:payload forConversation:Apptentive.shared.backend.conversationManager.activeConversation usingAuthToken:conversation.token inContext:context];
		}

		[context deleteObject:legacyMessage];
	}
}

@end
