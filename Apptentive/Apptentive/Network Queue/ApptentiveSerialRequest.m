//
//  ApptentiveSerialRequest.m
//  Apptentive
//
//  Created by Frank Schmitt on 12/16/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveSerialRequest.h"
#import "ApptentiveAttachment.h"
#import "ApptentiveRequestOperation.h"
#import "ApptentiveSerialRequestAttachment.h"
#import "ApptentiveConversation.h"
#import "ApptentivePayload.h"
#import "NSData+Encryption.h"
#import "ApptentiveUtilities.h"


@implementation ApptentiveSerialRequest

@dynamic apiVersion;
@dynamic attachments;
@dynamic contentType;
@dynamic conversationIdentifier;
@dynamic authToken;
@dynamic date;
@dynamic identifier;
@dynamic method;
@dynamic path;
@dynamic payload;
@dynamic encrypted;

+ (BOOL)enqueuePayload:(ApptentivePayload *)payload forConversation:(ApptentiveConversation *)conversation usingAuthToken:(nullable NSString *)authToken inContext:(NSManagedObjectContext *)context {
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

	ApptentiveAssertNotNil(context, @"Managed object context is nill");
	if (context == nil) {
		ApptentiveLogError(@"Unable encode enqueue request: managed object context is nil");
		return NO;
	}

	// create a child context on a private concurrent queue
	NSManagedObjectContext *childContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];

	// set parent context
	[childContext setParentContext:context];

	// execute the block on a background thread (this call returns immediatelly)
	[childContext performBlock:^{
        
        ApptentiveSerialRequest *request = (ApptentiveSerialRequest *)[[NSManagedObject alloc] initWithEntity:[NSEntityDescription entityForName:@"QueuedRequest" inManagedObjectContext:childContext] insertIntoManagedObjectContext:childContext];
        
        ApptentiveAssertNotNil(request, @"Can't load managed request object");
        if (request == nil) {
            ApptentiveLogError(@"Unable encode enqueue request '%@': can't load managed request object", payload.path);
            return;
        }
        
        payload.token = authToken;

        // FIXME: don't modify payload here
        if (conversation.state == ApptentiveConversationStateLoggedIn) {
            ApptentiveAssertNotNil(conversation.encryptionKey, @"Encryption key is nil for a logged-in conversation!");
            payload.encryptionKey = conversation.encryptionKey;
        }
        
        request.date = [NSDate date];
        request.path = payload.path;
        request.method = payload.method;
        request.identifier = payload.localIdentifier;
        request.conversationIdentifier = conversation.identifier;
        request.apiVersion = payload.apiVersion;
        request.authToken = authToken;
        request.contentType = payload.contentType;
        request.encrypted = payload.encrypted;
        request.payload = payload.payload;
        
        NSMutableArray *attachmentArray = [NSMutableArray arrayWithCapacity:payload.attachments.count];
        for (ApptentiveAttachment *attachment in payload.attachments) {
            [attachmentArray addObject:[ApptentiveSerialRequestAttachment queuedAttachmentWithName:attachment.name path:attachment.fullLocalPath MIMEType:attachment.contentType inContext:childContext]];
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
	}];

	return YES;
}

- (void)awakeFromFetch {
	if (self.conversationIdentifier.length > 0 && [self.path containsString:@"<cid>"]) {
		self.path = [self.path stringByReplacingOccurrencesOfString:@"<cid>" withString:self.conversationIdentifier];
	}
}

- (BOOL)isMessageRequest {
	// FIXME: replace with something less stupid.
	return [self.path containsString:@"message"] && [self.method isEqualToString:@"POST"];
}

@end
