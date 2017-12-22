//
//  ApptentiveLegacyMessage.m
//  Apptentive
//
//  Created by Andrew Wooster on 10/6/12.
//  Copyright (c) 2012 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveLegacyMessage.h"
#import "ApptentiveAttachment.h"
#import "ApptentiveBackend.h"
#import "ApptentiveLegacyFileAttachment.h"
#import "ApptentiveLegacyMessageSender.h"
#import "ApptentiveMessage.h"
#import "ApptentiveMessageManager.h"
#import "ApptentiveMessagePayload.h"
#import "ApptentiveMessageSender.h"
#import "ApptentivePerson.h"
#import "ApptentiveSerialRequest.h"
#import "Apptentive_Private.h"

NS_ASSUME_NONNULL_BEGIN


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

+ (void)enqueueUnsentMessagesInContext:(NSManagedObjectContext *)context forConversation:(ApptentiveConversation *)conversation oldAttachmentPath:(NSString *)oldAttachmentPath newAttachmentPath:(NSString *)newAttachmentPath {
	ApptentiveAssertNotNil(context, @"Context is nil");
	ApptentiveAssertNotNil(conversation, @"Conversation is nil");
	ApptentiveAssertNotNil(oldAttachmentPath, @"Old attachment path is nil");
	ApptentiveAssertNotNil(newAttachmentPath, @"New attachment path is nil");

	NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"ATMessage"];
	request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"clientCreationTime" ascending:YES]];

	NSError *error;
	NSArray *unsentMessages = [context executeFetchRequest:request error:&error];

	if (unsentMessages == nil) {
		ApptentiveLogError(@"Unable to retrieve unsent messages: %@", error);
		return;
	}

	for (ApptentiveLegacyMessage *legacyMessage in unsentMessages) {
		NSInteger pendingState = legacyMessage.pendingState.integerValue;

		// only migrate 'sending' and 'failed' messages (delete the rest)
		if (pendingState == ATPendingMessageStateSending || pendingState == ATPendingMessageStateError) {
			NSMutableArray *attachments = [NSMutableArray arrayWithCapacity:legacyMessage.attachments.count];
			for (ApptentiveLegacyFileAttachment *legacyAttachment in legacyMessage.attachments) {
				// Move the file from its current location into the conversation's container.
				NSString *oldPath = [oldAttachmentPath stringByAppendingPathComponent:legacyAttachment.localPath];

				// QLPreviewController needs a valid extension. Try to add one if it's missing.
				NSString *filename = oldPath.lastPathComponent;
				if (filename.pathExtension.length == 0) {
					filename = [filename stringByAppendingPathExtension:legacyAttachment.extension];
				}

				NSString *newPath = [newAttachmentPath stringByAppendingPathComponent:filename];

				if (![[NSFileManager defaultManager] moveItemAtPath:oldPath toPath:newPath error:&error]) {
					ApptentiveLogError(@"Unable to move attachment file to %@: %@", newPath, error);
					continue;
				}

				ApptentiveAttachment *attachment = [[ApptentiveAttachment alloc] initWithPath:newPath contentType:legacyAttachment.mimeType name:legacyAttachment.name];
				ApptentiveArrayAddObject(attachments, attachment);
			}

			NSDictionary *customData = @{};
			if (legacyMessage.customData) {
				customData = [NSKeyedUnarchiver unarchiveObjectWithData:legacyMessage.customData];
			};

			ApptentiveMessage *message = [[ApptentiveMessage alloc] initWithBody:legacyMessage.body attachments:attachments automated:legacyMessage.automated.boolValue customData:customData creationDate:[NSDate dateWithTimeIntervalSince1970:legacyMessage.clientCreationTime.doubleValue]];

			if (legacyMessage.hidden.boolValue) {
				message.state = ApptentiveMessageStateHidden;
			}

			ApptentiveMessagePayload *payload = [[ApptentiveMessagePayload alloc] initWithMessage:message];
			ApptentiveAssertNotNil(payload, @"Failed to create a message payload");

			if (payload != nil) {
				[ApptentiveSerialRequest enqueuePayload:payload forConversation:conversation usingAuthToken:conversation.token inContext:context];
			}
		}

		[context deleteObject:legacyMessage];
	}

	if ([[NSFileManager defaultManager] fileExistsAtPath:oldAttachmentPath] && ![[NSFileManager defaultManager] removeItemAtPath:oldAttachmentPath error:&error]) {
		ApptentiveLogError(@"Unable to remove legacy attachments directory (%@): %@", oldAttachmentPath, error);
	}
}

@end

NS_ASSUME_NONNULL_END
