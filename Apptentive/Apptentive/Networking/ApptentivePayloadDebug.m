//
//  ApptentivePayloadDebug.m
//  Apptentive
//
//  Created by Alex Lementuev on 7/27/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import "ApptentivePayloadDebug.h"
#import "ApptentiveSerialRequest.h"
#import "ApptentiveUtilities.h"

NS_ASSUME_NONNULL_BEGIN


@implementation ApptentivePayloadDebug

+ (void)printPayloadSendingQueueWithContext:(NSManagedObjectContext *)context title:(NSString *)title {
	if (!ApptentiveCanLogLevel(ApptentiveLogLevelVerbose)) {
		return;
	}

	NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"QueuedRequest"];
	fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"date" ascending:YES]];

	NSError *error;
	NSArray *queuedRequests = [context executeFetchRequest:fetchRequest error:&error];

	if (queuedRequests.count == 0) {
		ApptentiveLogVerbose(ApptentiveLogTagPayload, @"%@ (%ld payload(s))", title, (unsigned long)queuedRequests.count);
		return;
	}

	NSMutableArray *rows = [NSMutableArray new];
	[rows addObject:@[
		@"type",
		@"atts",
		@"conversationId",
		@"authToken",
		@"date",
		@"identifier",
		@"method",
		@"path",
		@"payload",
		@"enc",
		@"contentType"
	]];

	NSMutableString *moreInfo = [NSMutableString new];
	NSInteger row = 1;
	NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
	formatter.dateStyle = NSDateFormatterShortStyle;
	for (ApptentiveSerialRequest *request in queuedRequests) {
		if (request.authToken != nil) {
			if (moreInfo.length > 0) {
				[moreInfo appendString:@"\n"];
			}
			[moreInfo appendFormat:@"JWT-%ld: %@", (unsigned long)row, request.authToken];
		}
		[rows addObject:@[
			request.type ?: @"nil",
			[NSString stringWithFormat:@"%ld", (unsigned long)request.attachments.count],
			request.conversationIdentifier ?: @"nil",
			request.authToken ? [NSString stringWithFormat:@"JWT-%ld", (unsigned long)row] : @"nil",
			request.date ? [formatter stringFromDate:request.date] : @"nil",
			request.identifier ?: @"nil",
			request.method ?: @"nil",
			request.path ?: @"nil",
			[NSString stringWithFormat:@"%ld", (unsigned long)request.payload.length],
			[NSString stringWithFormat:@"%d", request.encrypted ? 1 : 0],
			request.contentType ?: @"nil"
		]];
	}

	ApptentiveLogVerbose(ApptentiveLogTagPayload, @"%@ (%ld payload(s)):\n%@\n%@\n-", title, (unsigned long)queuedRequests.count, [ApptentiveUtilities formatAsTableRows:rows], moreInfo);
}

@end

NS_ASSUME_NONNULL_END
