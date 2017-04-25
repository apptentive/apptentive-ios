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


@implementation ApptentiveSerialRequest

@dynamic apiVersion;
@dynamic attachments;
@dynamic conversationIdentifier;
@dynamic authToken;
@dynamic date;
@dynamic identifier;
@dynamic method;
@dynamic path;
@dynamic payload;

+ (BOOL)enqueuePayload:(ApptentivePayload *)payload forConversation:(ApptentiveConversation *)conversation usingAuthToken:(NSString *)authToken inContext:(NSManagedObjectContext *)context {
	ApptentiveAssertNotNil(conversation);
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

	NSError *error;
	request.payload = payload.payload;

	NSMutableArray *attachmentArray = [NSMutableArray arrayWithCapacity:payload.attachments.count];
	for (ApptentiveAttachment *attachment in payload.attachments) {
		[attachmentArray addObject:[ApptentiveSerialRequestAttachment queuedAttachmentWithName:attachment.name path:attachment.fullLocalPath MIMEType:attachment.contentType inContext:context]];
	}
	request.attachments = [NSOrderedSet orderedSetWithArray:attachmentArray];

	// Doing this synchronously triggers Core Data's recursive save detection.
	[context performBlock:^{
		NSError *saveError;
		if (![context save:&saveError]) {
			ApptentiveLogError(@"Error saving request for %@ to queue: %@", payload.path, error);
		}
	}];

	return YES;
}

- (NSString *)contentType {
	return @"application/json";
}

- (void)awakeFromFetch {
	if (self.conversationIdentifier.length > 0 && [self.path containsString:@"<cid>"]) {
		self.path = [self.path stringByReplacingOccurrencesOfString:@"<cid>" withString:self.conversationIdentifier];
	}
}

@end
