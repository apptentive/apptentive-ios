//
//  ApptentiveMessage.m
//  Apptentive
//
//  Created by Frank Schmitt on 3/22/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveMessage.h"
#import "ApptentiveMessageSender.h"
#import "ApptentiveAttachment.h"

@implementation ApptentiveMessage

- (instancetype)initWithJSON:(NSDictionary *)JSON {
	self = [super init];

	if (![JSON isKindOfClass:[NSDictionary class]]) {
		return nil;
	}

	if (self) {
		if (![JSON isKindOfClass:[NSDictionary class]]) {
			return nil;
		}

		_body = JSON[@"body"];

		NSMutableArray *mutableAttachments;
		if ([JSON[@"attachments"] isKindOfClass:[NSArray class]]) {
			for (NSDictionary *attachmentJSON in JSON[@"attachments"]) {
				ApptentiveAttachment *attachment = [[ApptentiveAttachment alloc] initWithJSON:attachmentJSON];
				if (attachment != nil) {
					[mutableAttachments addObject:attachment];
				}
			}
		}
		_attachments = [mutableAttachments copy];

		_sender = [[ApptentiveMessageSender alloc] initWithJSON:JSON[@"sender"]];

		_sentDate = [NSDate dateWithTimeIntervalSince1970:[JSON[@"created_at"] doubleValue]];
		_pendingMessageIdentifier = JSON[@"nonce"];

		if ([JSON[@"hidden"] isKindOfClass:[NSNumber class]] && [JSON[@"hidden"] boolValue]) {
			_state = ApptentiveMessageStateHidden;
		} else {
			// If not sent by local user, will get updated to read/unread by message manager
			_state = ApptentiveMessageStateSent;
		}

		_identifier = JSON[@"id"];
	}

	return self;
}

- (instancetype)initWithBody:(NSString *)body attachments:(NSArray *)attachments sender:(ApptentiveMessageSender *)sender {
	self = [super init];

	if (self) {
		_body = body;
		_attachments = attachments;
		_sender = sender;

		_sentDate = [NSDate date];
		_pendingMessageIdentifier = [NSUUID UUID].UUIDString;
		_state = ApptentiveMessageStatePending;
	}

	return self;
}

@end

@implementation ApptentiveMessage (QuickLook)

- (NSInteger)numberOfPreviewItemsInPreviewController:(QLPreviewController *)controller {
	return self.attachments.count;
}

- (id<QLPreviewItem>)previewController:(QLPreviewController *)controller previewItemAtIndex:(NSInteger)index {
	return [self.attachments objectAtIndex:index];
}

@end
