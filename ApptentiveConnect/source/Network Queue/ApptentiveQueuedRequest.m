//
//  ApptentiveQueuedRequest.m
//  ApptentiveConnect
//
//  Created by Frank Schmitt on 12/16/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveQueuedRequest.h"
#import "ApptentiveFileAttachment.h"
#import "ApptentiveQueuedAttachment.h"

@implementation ApptentiveQueuedRequest

@dynamic attachments;
@dynamic date;
@dynamic identifier;
@dynamic method;
@dynamic path;
@dynamic payload;

+ (void)enqueueRequestWithPath:(NSString *)path method:(NSString *)method payload:(NSDictionary *)payload attachments:(NSOrderedSet *)attachments identifier:(NSString *)identifier inContext:(NSManagedObjectContext *)context {
	ApptentiveQueuedRequest *request = (ApptentiveQueuedRequest *)[[NSManagedObject alloc] initWithEntity:[NSEntityDescription entityForName:@"QueuedRequest" inManagedObjectContext:context] insertIntoManagedObjectContext:context];

	request.date = [NSDate date];
	request.path = path;
	request.method = method;
	request.identifier = identifier;

	NSError *error;
	request.payload = [NSJSONSerialization dataWithJSONObject:payload options:0 error:&error];

	if (!request.payload) {
		ApptentiveLogError(@"Unable to encode payload for %@ request: %@", path, error);
		return;
	}

	NSMutableArray *attachmentArray = [NSMutableArray arrayWithCapacity:attachments.count];
	for (ApptentiveFileAttachment *attachment in attachments) {
		[attachmentArray addObject:[ApptentiveQueuedAttachment queuedAttachmentWithName:attachment.name path:attachment.fullLocalPath MIMEType:attachment.mimeType inContext:context]];
	}
	request.attachments = [NSOrderedSet orderedSetWithArray:attachmentArray];

	// Doing this synchronously triggers Core Data's recursive save detection.
	[context performBlock:^{
		NSError *saveError;
		if (![context save:&saveError]) {
			ApptentiveLogError(@"Error saving request for %@ to queue: %@", path, error);
		}
	}];
}

@end
