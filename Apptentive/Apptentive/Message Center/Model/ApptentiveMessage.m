//
//  ApptentiveMessage.m
//  Apptentive
//
//  Created by Frank Schmitt on 3/22/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveMessage.h"
#import "ApptentiveAttachment.h"
#import "ApptentiveMessageSender.h"

NS_ASSUME_NONNULL_BEGIN

static NSString *const IdentifierKey = @"identifier";
static NSString *const LocalIdentifierKey = @"localIdentifier";
static NSString *const SentDateKey = @"sentDate";
static NSString *const AttachmentsKey = @"attachments";
static NSString *const SenderKey = @"sender";
static NSString *const BodyKey = @"body";
static NSString *const StateKey = @"state";
static NSString *const AutomatedKey = @"automated";
static NSString *const CustomDataKey = @"customData";
static NSString *const InboundKey = @"inboundKey";


@interface ApptentiveMessage ()

@property (readwrite, nullable, nonatomic) NSString *identifier;
@property (readwrite, nonatomic) NSString *localIdentifier;
@property (readwrite, nonatomic) NSDate *sentDate;

@end


@implementation ApptentiveMessage

+ (BOOL)supportsSecureCoding {
	return YES;
}

- (nullable instancetype)initWithJSON:(NSDictionary *)JSON {
	self = [super init];

	if (self) {
		if (![JSON isKindOfClass:[NSDictionary class]]) {
			ApptentiveLogError(@"Can't init %@: invalid json: %@", NSStringFromClass([self class]), JSON);
			return nil;
		}

		_body = ApptentiveDictionaryGetString(JSON, @"body");

		NSArray *attachmentsArray = ApptentiveDictionaryGetArray(JSON, @"attachments");
		if (attachmentsArray.count > 0) {
			NSMutableArray *attachments = [NSMutableArray arrayWithCapacity:attachmentsArray.count];

			for (id attachmentDict in attachmentsArray) {
				if (![attachmentDict isKindOfClass:[NSDictionary class]]) {
					continue;
				}

				ApptentiveAttachment *attachment = [[ApptentiveAttachment alloc] initWithJSON:attachmentDict];
				ApptentiveArrayAddObject(attachments, attachment);
			}

			_attachments = attachments;
		}

		_sender = [[ApptentiveMessageSender alloc] initWithJSON:JSON[@"sender"]];
		if (_sender == nil) {
			ApptentiveLogError(@"Can't init %@: sender can't be created", NSStringFromClass([self class]));
			return nil;
		}

		_sentDate = [NSDate dateWithTimeIntervalSince1970:[JSON[@"created_at"] doubleValue]];
		_localIdentifier = JSON[@"nonce"];

		if ([JSON[@"inbound"] isKindOfClass:[NSNumber class]] && ![JSON[@"inbound"] boolValue]) {
			_inbound = NO;
		} else {
			_inbound = YES;
		}

		if ([JSON[@"hidden"] isKindOfClass:[NSNumber class]] && [JSON[@"hidden"] boolValue]) {
			_state = ApptentiveMessageStateHidden;
		} else {
			if (_inbound) {
				_state = ApptentiveMessageStateSent;
			} else {
				_state = ApptentiveMessageStateUnread;
			}
		}

		_identifier = ApptentiveDictionaryGetString(JSON, @"id");
	}

	return self;
}

- (nullable instancetype)initWithBody:(nullable NSString *)body attachments:(nullable NSArray *)attachments automated:(BOOL)automated customData:(nullable NSDictionary *)customData creationDate:(nonnull NSDate *)creationDate {
	self = [super init];

	if (self) {
		_body = body;
		_attachments = attachments ?: @[];

		_automated = automated;
		_customData = customData;

		_sentDate = creationDate;
		_state = ApptentiveMessageStatePending;

		_inbound = YES;
	}

	return self;
}

- (nullable instancetype)initWithCoder:(NSCoder *)coder {
	self = [super init];
	if (self) {
		_identifier = [coder decodeObjectOfClass:[NSString class] forKey:IdentifierKey];
		_localIdentifier = [coder decodeObjectOfClass:[NSString class] forKey:LocalIdentifierKey];
		_sentDate = [coder decodeObjectOfClass:[NSDate class] forKey:SentDateKey];
		_attachments = [coder decodeObjectOfClass:[ApptentiveAttachment class] forKey:AttachmentsKey];
		_sender = [coder decodeObjectOfClass:[ApptentiveMessageSender class] forKey:SenderKey];
		_body = [coder decodeObjectOfClass:[NSString class] forKey:BodyKey];
		_state = [coder decodeIntegerForKey:StateKey];
		_automated = [coder decodeBoolForKey:AutomatedKey];
		_customData = [coder decodeObjectOfClass:[NSDictionary class] forKey:CustomDataKey];
		_inbound = [coder decodeBoolForKey:InboundKey];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
	[coder encodeObject:self.identifier forKey:IdentifierKey];
	[coder encodeObject:self.localIdentifier forKey:LocalIdentifierKey];
	[coder encodeObject:self.sentDate forKey:SentDateKey];
	[coder encodeObject:self.attachments forKey:AttachmentsKey];
	[coder encodeObject:self.sender forKey:SenderKey];
	[coder encodeObject:self.body forKey:BodyKey];
	[coder encodeInteger:self.state forKey:StateKey];
	[coder encodeBool:self.automated forKey:AutomatedKey];
	[coder encodeObject:self.customData forKey:CustomDataKey];
	[coder encodeBool:self.inbound forKey:InboundKey];
}

- (id)copyWithZone:(nullable NSZone *)zone {
	ApptentiveMessage *copy = [[ApptentiveMessage alloc] initWithBody:self.body attachments:self.attachments automated:self.automated customData:self.customData creationDate:self.sentDate];

	copy.identifier = self.identifier;
	copy.localIdentifier = self.localIdentifier;
	copy.sender = self.sender;
	copy.state = self.state;

	return copy;
}

- (ApptentiveMessage *)mergedWith:(ApptentiveMessage *)messageFromServer {
	_identifier = messageFromServer.identifier;
	_sentDate = messageFromServer.sentDate;

	switch (self.state) {
		case ApptentiveMessageStatePending:
		case ApptentiveMessageStateSending:
		case ApptentiveMessageStateWaiting:
		case ApptentiveMessageStateFailedToSend:
		case ApptentiveMessageStateUndefined:
			_state = ApptentiveMessageStateSent;
			break;
		default:
			// Trust local state over server state
			break;
	}

	if (self.attachments.count == messageFromServer.attachments.count) {
		NSInteger i = 0;
		NSMutableArray *updatedAttachments = [NSMutableArray arrayWithCapacity:self.attachments.count];
		for (ApptentiveAttachment *attachment in self.attachments) {
			ApptentiveAttachment *attachmentFromServer = messageFromServer.attachments[i++];

			ApptentiveAttachment *updatedAttachment = [attachment mergedWith:attachmentFromServer];
			ApptentiveArrayAddObject(updatedAttachments, updatedAttachment);
		}

		_attachments = updatedAttachments;
	} else {
		ApptentiveLogError(@"Mismatch in number of attachments between client and server.");
	}

	return self;
}

- (void)updateWithLocalIdentifier:(NSString *)localIdentifier {
	_localIdentifier = localIdentifier;
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

NS_ASSUME_NONNULL_END
