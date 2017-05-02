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

+ (BOOL)enqueuePayload:(ApptentivePayload *)payload forConversation:(ApptentiveConversation *)conversation usingAuthToken:(NSString *)authToken inContext:(NSManagedObjectContext *)context {
	ApptentiveAssertNotNil(conversation, @"Conversation id is nil");
	if (conversation == nil) {
		return NO;
	}

	ApptentiveAssertTrue(conversation.state != ApptentiveConversationStateUndefined && conversation.state != ApptentiveConversationStateLoggedOut, @"Unexpected conversation state: %ld", conversation.state);
	if (conversation.state == ApptentiveConversationStateUndefined ||
		conversation.state == ApptentiveConversationStateLoggedOut) {
		return NO;
	}

	ApptentiveAssertNotNil(context, @"Managed object context is nill");
	if (context == nil) {
		ApptentiveLogError(@"Unable encode enqueue request: managed object context is nil");
		return NO;
	}

	ApptentiveSerialRequest *request = (ApptentiveSerialRequest *)[[NSManagedObject alloc] initWithEntity:[NSEntityDescription entityForName:@"QueuedRequest" inManagedObjectContext:context] insertIntoManagedObjectContext:context];

	ApptentiveAssertNotNil(request, @"Can't load managed request object");
	if (request == nil) {
		ApptentiveLogError(@"Unable encode enqueue request '%@': can't load managed request object", payload.path);
		return NO;
	}

	request.date = [NSDate date];
	request.path = payload.path;
	request.method = payload.method;
	request.identifier = payload.localIdentifier;
	request.conversationIdentifier = conversation.identifier;
	request.apiVersion = payload.apiVersion;
	request.authToken = authToken;
	request.contentType = @"application/json";

	NSError *error;
	request.payload = payload.payload;

	NSMutableArray *attachmentArray = [NSMutableArray arrayWithCapacity:payload.attachments.count];
	for (ApptentiveAttachment *attachment in payload.attachments) {
		[attachmentArray addObject:[ApptentiveSerialRequestAttachment queuedAttachmentWithName:attachment.name path:attachment.fullLocalPath MIMEType:attachment.contentType inContext:context]];
	}
	request.attachments = [NSOrderedSet orderedSetWithArray:attachmentArray];

	if (conversation.state == ApptentiveConversationStateLoggedIn) {
		ApptentiveAssertNotNil(conversation.encryptionKey, @"Encryption key is nil for a logged-in conversation!");

		[request encryptWithKey:conversation.encryptionKey];
	}

	// Doing this synchronously triggers Core Data's recursive save detection.
	[context performBlock:^{
		NSError *saveError;
		if (![context save:&saveError]) {
			ApptentiveLogError(@"Error saving request for %@ to queue: %@", payload.path, error);
		}
	}];

	return YES;
}

- (void)awakeFromFetch {
	if (self.conversationIdentifier.length > 0 && [self.path containsString:@"<cid>"]) {
		self.path = [self.path stringByReplacingOccurrencesOfString:@"<cid>" withString:self.conversationIdentifier];
	}
}

- (BOOL)encryptWithKey:(NSData *)key {
	NSError *error;
	NSDictionary *JSONPayload = [NSJSONSerialization JSONObjectWithData:self.payload options:0 error:&error];

	ApptentiveAssertNotNil(JSONPayload, @"Unable to read JSON-encoded payload data: %@", error);

	if (JSONPayload == nil) {
		return NO;
	}

	NSMutableDictionary *mutablePayload = [JSONPayload mutableCopy];
	mutablePayload[@"token"] = self.authToken;

	NSData *JSONPayloadWithToken = [NSJSONSerialization dataWithJSONObject:mutablePayload options:0 error:&error];

	ApptentiveAssertNotNil(JSONPayloadWithToken, @"Unable to encode payload data as JSON: %@", error);

	if (JSONPayloadWithToken == nil) {
		return NO;
	}

	NSData *initializationVector = [ApptentiveUtilities secureRandomDataOfLength:16];

	ApptentiveAssertTrue(initializationVector.length > 0, "Unable to generate random initialization vector.");

	if (initializationVector == nil) {
		return NO;
	}

	NSData *encryptedPayload = [JSONPayloadWithToken apptentive_dataEncryptedWithKey:key initializationVector:initializationVector];

	ApptentiveAssertNotNil(encryptedPayload, @"Unable to encrypt payload");

	self.payload = encryptedPayload;
	self.contentType = @"application/octet-stream";

	return self.payload != nil;
}

@end
