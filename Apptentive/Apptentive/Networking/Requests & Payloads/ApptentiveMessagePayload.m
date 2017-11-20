//
//  ApptentiveMessagePayload.m
//  Apptentive
//
//  Created by Frank Schmitt on 4/19/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveMessagePayload.h"
#import "ApptentiveAttachment.h"
#import "ApptentiveMessage.h"
#import "ApptentiveUtilities.h"
#import "NSData+Encryption.h"
#import "NSMutableData+Types.h"

NS_ASSUME_NONNULL_BEGIN


@interface ApptentiveMessagePayload ()

@property (strong, nonatomic) NSDictionary *superContents;

@end


@implementation ApptentiveMessagePayload

- (nullable instancetype)initWithMessage:(ApptentiveMessage *)message {
	self = [super init];

	if (self) {
		if (message == nil) {
			ApptentiveLogError(@"Can't init %@: message is nil", NSStringFromClass([self class]));
			return nil;
		}

		_message = message;
		_superContents = super.contents;
		_boundary = [ApptentiveUtilities randomStringOfLength:20];

		[message updateWithLocalIdentifier:_superContents[@"nonce"]];
	}

	return self;
}

- (NSString *)type {
	return @"message";
}

- (NSString *)contentType {
	return [[NSString alloc] initWithFormat:@"%@;boundary=%@", self.encrypted ? @"multipart/encrypted" : @"multipart/mixed", self.boundary];
}

- (NSString *)path {
	return @"conversations/<cid>/messages";
}

- (NSDictionary *)JSONDictionary {
	NSMutableDictionary *JSON = [self.superContents mutableCopy];

	if (self.message.body) {
		JSON[@"body"] = self.message.body;
	}

	JSON[@"automated"] = @(self.message.automated);
	JSON[@"hidden"] = @(self.message.state == ApptentiveMessageStateHidden);

	if (self.message.customData) {
		NSDictionary *customDataDictionary = self.message.customData;
		if (customDataDictionary && customDataDictionary.count) {
			JSON[@"custom_data"] = customDataDictionary;
		}
	}

	return JSON;
}

- (nullable NSData *)payload {
	BOOL encrypted = self.encrypted;

	NSString *boundary = self.boundary;
	NSMutableData *data = [NSMutableData new];

	// First write the message body out as the first "part".
	NSMutableString *header = [NSMutableString new];
	[header appendFormat:@"--%@\r\n", boundary];

	NSMutableString *part = [NSMutableString new];
	[part appendString:@"Content-Disposition: form-data; name=\"message\"\r\n"];
	[part appendString:@"Content-Type: application/json;charset=UTF-8\r\n"];
	[part appendString:@"\r\n"];
	[part appendString:[[NSString alloc] initWithData:[self marshalForSending] encoding:NSUTF8StringEncoding]];
	[part appendString:@"\r\n"];

	NSData *partBytes = [part dataUsingEncoding:NSUTF8StringEncoding];

	if (encrypted) {
		[header appendString:@"Content-Disposition: form-data; name=\"message\"\r\n"];
		[header appendString:@"Content-Type: application/octet-stream\r\n"];
		[header appendString:@"\r\n"];
		[data apptentive_appendString:header];
		[data appendData:[partBytes apptentive_dataEncryptedWithKey:self.encryptionKey]];
		[data apptentive_appendString:@"\r\n"];
	} else {
		[data apptentive_appendString:header];
		[data appendData:partBytes];
	}

	// Then append attachments
	if (self.attachments.count > 0) {
		for (ApptentiveAttachment *attachment in self.attachments) {
			ApptentiveLogVerbose(ApptentiveLogTagPayload, @"Starting to write an attachment part.");
			[data apptentive_appendFormat:@"--%@\r\n", boundary];
			NSMutableString *attachmentEnvelope = [NSMutableString new];
			[attachmentEnvelope appendFormat:@"Content-Disposition: form-data; name=\"file[]\"; filename=\"%@\"\r\n", attachment.name];
			[attachmentEnvelope appendFormat:@"Content-Type: %@\r\n", attachment.contentType];
			[attachmentEnvelope appendString:@"\r\n"];
			NSMutableData *attachmentBytes = [NSMutableData new];

			ApptentiveLogVerbose(ApptentiveLogTagPayload, @"Writing attachment envelope: %@", attachmentEnvelope);
			[attachmentBytes apptentive_appendString:attachmentEnvelope];

			// TODO: downscale image
			[attachmentBytes appendData:[NSData dataWithContentsOfFile:attachment.fullLocalPath]];

			if (encrypted) {
				// If encrypted, each part must be encrypted, and wrapped in a plain text set of headers.
				NSMutableString *encryptionEnvelope = [NSMutableString new];
				[encryptionEnvelope appendString:@"Content-Disposition: form-data; name=\"file[]\"\r\n"];
				[encryptionEnvelope appendString:@"Content-Type: application/octet-stream\r\n"];
				[encryptionEnvelope appendString:@"\r\n"];

				ApptentiveLogVerbose(ApptentiveLogTagPayload, @"Writing encrypted envelope: %@", encryptionEnvelope);
				[data apptentive_appendString:encryptionEnvelope];

				ApptentiveLogVerbose(ApptentiveLogTagPayload, @"Encrypting attachment bytes: %ld", attachmentBytes.length);
				NSData *encryptedAttachment = [attachmentBytes apptentive_dataEncryptedWithKey:self.encryptionKey];
				ApptentiveLogVerbose(ApptentiveLogTagPayload, @"Writing encrypted attachment bytes: %ld", encryptedAttachment.length);
				[data appendData:encryptedAttachment];
			} else {
				ApptentiveLogVerbose(ApptentiveLogTagPayload, @"Writing attachment bytes: %ld", attachmentBytes.length);
				[data appendData:attachmentBytes];
			}
			[data apptentive_appendString:@"\r\n"];
		}
	}
	[data apptentive_appendFormat:@"--%@--", boundary];

	ApptentiveLogVerbose(ApptentiveLogTagPayload, @"Total payload body bytes: %ld", data.length);
	return data;
}

- (nullable NSArray *)attachments {
	return self.message.attachments ?: @[];
}

- (nullable NSString *)localIdentifier {
	return self.message.localIdentifier;
}

@end

NS_ASSUME_NONNULL_END
