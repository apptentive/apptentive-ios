//
//  ApptentiveSerialRequest.m
//  Apptentive
//
//  Created by Frank Schmitt on 12/16/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveSerialRequest.h"
#import "ApptentiveAttachment.h"
#import "ApptentiveConversation.h"
#import "ApptentivePayload.h"
#import "ApptentivePayloadDebug.h"
#import "ApptentiveRequestOperation.h"
#import "ApptentiveSerialRequestAttachment.h"
#import "ApptentiveUtilities.h"
#import "Apptentive_Private.h"
#import "NSData+Encryption.h"
#import "ApptentiveDispatchQueue.h"

NS_ASSUME_NONNULL_BEGIN


@implementation ApptentiveSerialRequest

@dynamic apiVersion;
@dynamic attachments;
@dynamic type;
@dynamic contentType;
@dynamic conversationIdentifier;
@dynamic authToken;
@dynamic date;
@dynamic identifier;
@dynamic method;
@dynamic path;
@dynamic payload;
@dynamic encrypted;

@synthesize messageIdentifier = _messageIdentifier;

+ (BOOL)enqueuePayload:(ApptentivePayload *)payload forConversation:(ApptentiveConversation *)conversation usingAuthToken:(nullable NSString *)authToken inContext:(NSManagedObjectContext *)context {
	ApptentiveAssertOperationQueue(Apptentive.shared.operationQueue);

	ApptentiveAssertNotNil(context, @"Context is nil");
	if (context == nil) {
		return NO;
	}

	ApptentiveAssertNotNil(payload, @"Attempted to enqueue nil payload");
	if (payload == nil) {
		return NO;
	}

	ApptentiveAssertNotNil(conversation, @"Attempted to enqueue payload with nil conversation: %@", payload);
	if (conversation == nil) {
		return NO;
	}

	ApptentiveAssertTrue(conversation.state != ApptentiveConversationStateUndefined && conversation.state != ApptentiveConversationStateLoggedOut, @"Attempted to enqueue payload with wrong conversation state (%@): %@", NSStringFromApptentiveConversationState(conversation.state), payload);
	if (conversation.state == ApptentiveConversationStateUndefined ||
		conversation.state == ApptentiveConversationStateLoggedOut) {
		return NO;
	}

	ApptentiveAssertNotNil(context, @"Managed object context is nil");
	if (context == nil) {
		ApptentiveLogError(@"Unable encode enqueue request: managed object context is nil");
		return NO;
	}

	// create a child context on a private concurrent queue
	NSManagedObjectContext *childContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];

	// set parent context
	[childContext setParentContext:context];

	// FIXME: don't modify payload here
	payload.token = authToken;

	// FIXME: don't modify payload here
	if (conversation.state == ApptentiveConversationStateLoggedIn) {
		ApptentiveAssertNotNil(conversation.encryptionKey, @"Encryption key is nil for a logged-in conversation!");
		payload.encryptionKey = conversation.encryptionKey;
	}

	// capture all the data here to avoid concurrency issues
	NSString *payloadPath = payload.path;
	NSString *payloadMethod = payload.method;
	NSString *payloadIdentifier = payload.localIdentifier;
	NSString *conversationIdentifier = conversation.identifier;
	NSString *payloadApiVersion = payload.apiVersion;
	NSString *payloadContentType = payload.contentType;
	BOOL payloadEncrypted = payload.encrypted;
	NSData *payloadData = payload.payload;
	NSString *payloadType = payload.type;
	NSArray *payloadAttachments = payload.attachments;

	// execute the block on a background thread (this call returns immediatelly)
	[childContext performBlockAndWait:^{

	  ApptentiveSerialRequest *request = (ApptentiveSerialRequest *)[[NSManagedObject alloc] initWithEntity:[NSEntityDescription entityForName:@"QueuedRequest" inManagedObjectContext:childContext] insertIntoManagedObjectContext:childContext];

	  ApptentiveAssertNotNil(request, @"Can't load managed request object");
	  if (request == nil) {
		  ApptentiveLogError(@"Unable encode enqueue request '%@': can't load managed request object", payloadPath);
		  return;
	  }

	  request.date = [NSDate date];
	  request.path = payloadPath;
	  request.method = payloadMethod;
	  request.identifier = payloadIdentifier;
	  request.conversationIdentifier = conversationIdentifier;
	  request.apiVersion = payloadApiVersion;
	  request.authToken = authToken;
	  request.contentType = payloadContentType;
	  request.encrypted = payloadEncrypted;
	  request.payload = payloadData;
	  request.type = payloadType;

	  NSMutableArray *attachmentArray = [NSMutableArray arrayWithCapacity:payload.attachments.count];
	  for (ApptentiveAttachment *attachment in payloadAttachments) {
		  ApptentiveArrayAddObject(attachmentArray, [ApptentiveSerialRequestAttachment queuedAttachmentWithName:attachment.name path:attachment.fullLocalPath MIMEType:attachment.contentType inContext:childContext]);
	  }
	  request.attachments = [NSOrderedSet orderedSetWithArray:attachmentArray];

	  // save child context
	  NSError *saveError;
	  if (![childContext save:&saveError]) {
		  ApptentiveLogError(@"Unable to save temporary managed object context: %@", saveError);
	  }

	  // save parent context
	  [context performBlockAndWait:^{
		NSError *parentSaveError;
		if (![context save:&parentSaveError]) {
			ApptentiveLogError(@"Unable to save parent managed object context: %@", parentSaveError);
		}
	  }];

	  // print payload queue
	  [ApptentivePayloadDebug printPayloadSendingQueueWithContext:childContext title:@"Enqueue payload"];
	}];

	return YES;
}

- (void)printPayloadQueueWithContext:(NSManagedObjectContext *)context {
	NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"QueuedRequest"];
	fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"date" ascending:YES]];

	NSError *error;
	NSArray *queuedRequests = [context executeFetchRequest:fetchRequest error:&error];

	if (queuedRequests == nil) {
		ApptentiveLogError(ApptentiveLogTagPayload, @"Unable to fetch waiting network payloads.");
	}
}

- (void)awakeFromFetch {
	if (self.conversationIdentifier.length > 0 && [self.path containsString:@"<cid>"]) {
		self.path = [self.path stringByReplacingOccurrencesOfString:@"<cid>" withString:self.conversationIdentifier];
	}

	_messageIdentifier = [self.identifier copy];
}

- (BOOL)isMessageRequest {
	return self.messageIdentifier != nil;
}

@end

NS_ASSUME_NONNULL_END
