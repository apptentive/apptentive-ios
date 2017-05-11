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

static NSString *const IdentifierKey = @"identifier";
static NSString *const LocalIdentifierKey = @"localIdentifier";
static NSString *const SentDateKey = @"sentDate";
static NSString *const AttachmentsKey = @"attachments";
static NSString *const SenderKey = @"sender";
static NSString *const BodyKey = @"body";
static NSString *const StateKey = @"state";
static NSString *const AutomatedKey = @"automated";
static NSString *const CustomDataKey = @"customData";


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
				if (attachment != nil) {
					[attachments addObject:attachment];
				}
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

		if ([JSON[@"hidden"] isKindOfClass:[NSNumber class]] && [JSON[@"hidden"] boolValue]) {
			_state = ApptentiveMessageStateHidden;
		} else {
			// If not sent by local user, will get updated to read/unread by message manager
			_state = ApptentiveMessageStateSent;
		}

		_identifier = ApptentiveDictionaryGetString(JSON, @"id");
	}

	return self;
}

- (nullable instancetype)initWithBody:(NSString *)body attachments:(NSArray *)attachments senderIdentifier:(NSString *)senderIdentifier automated:(BOOL)automated customData:(NSDictionary *)customData {
	self = [super init];

	if (self) {
        if (senderIdentifier.length == 0) {
            ApptentiveLogError(@"Can't init %@: sender identifier is nil or empty", NSStringFromClass([self class]));
            return nil;
        }
        
		_body = body;
		_attachments = attachments ?: @[];
		_sender = [[ApptentiveMessageSender alloc] initWithName:nil identifier:senderIdentifier profilePhotoURL:nil];
        ApptentiveAssertNotNil(_sender, @"Apptentive message sender is nil");
        
		_automated = automated;
		_customData = customData;

		_sentDate = [NSDate date];
		_state = ApptentiveMessageStatePending;
	}

	return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
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
}

- (ApptentiveMessage *)mergedWith:(ApptentiveMessage *)messageFromServer {
	_identifier = messageFromServer.identifier;
	_sentDate = messageFromServer.sentDate;

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
