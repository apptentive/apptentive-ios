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
#import "ApptentivePerson.h"
#import "ApptentiveMessageManager.h"
#import "ApptentiveMessageSender.h"


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

	NSError *error;
	NSArray *unsentMessages = [context executeFetchRequest:request error:&error];

	if (unsentMessages == nil) {
		ApptentiveLogError(@"Unable to retrieve unsent messages: %@", error);
		return;
	}

	for (ApptentiveLegacyMessage *legacyMessage in unsentMessages) {
		NSInteger pendingState = legacyMessage.pendingState.integerValue;
		ApptentiveMessageManager *messageManager = Apptentive.shared.backend.conversationManager.messageManager;

		ApptentiveAssertNotNil(messageManager, @"Need an active message manager to migrate");

		NSMutableArray *attachments = [NSMutableArray arrayWithCapacity:legacyMessage.attachments.count];
		for (ApptentiveLegacyFileAttachment *legacyAttachment in legacyMessage.attachments) {
			// Move the file from its current location into the conversation's container.
			NSString *oldPath = [[self legacyDirectory] stringByAppendingPathComponent:legacyAttachment.localPath];

			// QLPreviewController needs a valid extension. Try to add one if it's missing.
			NSString *filename = oldPath.lastPathComponent;
			if (filename.pathExtension.length == 0) {
				filename = [filename stringByAppendingPathExtension:legacyAttachment.extension];
			}

			NSString *newPath = [messageManager.attachmentDirectoryPath stringByAppendingPathComponent:filename];

			if (![[NSFileManager defaultManager] moveItemAtPath:oldPath toPath:newPath error:&error]) {
				ApptentiveLogError(@"Unable to move attachment file to %@: %@", newPath, error);
				continue;
			}

			ApptentiveAttachment *attachment = [[ApptentiveAttachment alloc] initWithPath:newPath contentType:legacyAttachment.mimeType name:legacyAttachment.name];

			if (attachment != nil) {
				[attachments addObject:attachment];
			}
		}

		NSDictionary *customData = @{};
		if (legacyMessage.customData) {
			customData = [NSKeyedUnarchiver unarchiveObjectWithData:legacyMessage.customData];
		};

		NSString *senderName = nil;
		NSString *senderIdentifier = nil;
		NSURL *profilePhotoURL = nil;

		if (legacyMessage.sender) {
			senderName = legacyMessage.sender.name;
			senderIdentifier = legacyMessage.sender.apptentiveID;
			profilePhotoURL = profilePhotoURL != nil ? [NSURL URLWithString:legacyMessage.sender.profilePhotoURL] : nil;
		} else if (legacyMessage.sentByUser) {
			senderIdentifier = messageManager.localUserIdentifier;
		}


		ApptentiveMessageSender *sender = [[ApptentiveMessageSender alloc] initWithName:senderName identifier:senderIdentifier profilePhotoURL:profilePhotoURL];

		ApptentiveMessage *message = [[ApptentiveMessage alloc] initWithBody:legacyMessage.body attachments:attachments sender:sender automated:legacyMessage.automated.boolValue customData:customData];
		[message updateWithLocalIdentifier:legacyMessage.pendingMessageID];

		[messageManager appendMessage:message];

		// Add 'sending' and 'failed' messages to the payload send queue
		if (pendingState == ATPendingMessageStateSending || pendingState == ATPendingMessageStateError) {
			ApptentiveMessagePayload *payload = [[ApptentiveMessagePayload alloc] initWithMessage:message];
			ApptentiveAssertNotNil(payload, @"Failed to create a message payload");

			if (payload != nil) {
				[ApptentiveSerialRequest enqueuePayload:payload forConversation:conversation usingAuthToken:conversation.token inContext:context];
			}
		}

		[context deleteObject:legacyMessage];
	}
}

+ (NSString *)legacyDirectory {
	return [Apptentive.shared.backend.supportDirectoryPath stringByAppendingPathComponent:@"attachments"];
}

@end
