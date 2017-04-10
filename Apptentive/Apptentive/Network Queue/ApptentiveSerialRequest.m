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

+ (BOOL)enqueueRequestWithPath:(NSString *)path method:(NSString *)method payload:(NSDictionary *)payload attachments:(NSArray *)attachments identifier:(NSString *)identifier conversation:(ApptentiveConversation *)conversation inContext:(NSManagedObjectContext *)context {
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
		ApptentiveLogError(@"Unable encode enqueue request '%@': can't load managed request object", path);
		return NO;
	}

	request.date = [NSDate date];
	request.path = path;
	request.method = method;
	request.identifier = identifier;
	request.conversationIdentifier = conversation.identifier;
	request.apiVersion = [ApptentiveRequestOperation APIVersion];
    request.authToken = conversation.token; // TODO: for the encrypted storage that might be something else

	NSError *error;
	request.payload = [NSJSONSerialization dataWithJSONObject:payload options:0 error:&error];

	if (!request.payload) {
		ApptentiveLogError(@"Unable to encode payload for %@ request: %@", path, error);
		return NO;
	}

	NSMutableArray *attachmentArray = [NSMutableArray arrayWithCapacity:attachments.count];
	for (ApptentiveAttachment *attachment in attachments) {
		[attachmentArray addObject:[ApptentiveSerialRequestAttachment queuedAttachmentWithName:attachment.name path:attachment.fullLocalPath MIMEType:attachment.contentType inContext:context]];
	}
	request.attachments = [NSOrderedSet orderedSetWithArray:attachmentArray];

	// Doing this synchronously triggers Core Data's recursive save detection.
	[context performBlock:^{
		NSError *saveError;
		if (![context save:&saveError]) {
			ApptentiveLogError(@"Error saving request for %@ to queue: %@", path, error);
		}
	}];

	return YES;
}

@end
