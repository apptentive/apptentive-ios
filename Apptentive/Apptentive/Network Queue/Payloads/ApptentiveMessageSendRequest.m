//
//  ApptentiveMessageSendRequest.m
//  Apptentive
//
//  Created by Frank Schmitt on 4/21/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveMessageSendRequest.h"
#import "ApptentiveSerialRequest.h"
#import "ApptentiveSerialRequestAttachment.h"
#import "ApptentiveUtilities.h"


@interface ApptentiveMessageSendRequest ()

@property (readonly, nonatomic) NSString *boundary;

@end


@implementation ApptentiveMessageSendRequest

- (instancetype)initWithRequest:(ApptentiveSerialRequest *)request {
	self = [super init];

	if (self) {
		_request = request;
		_boundary = [ApptentiveUtilities randomStringOfLength:20];
	}

	return self;
}

- (NSString *)apiVersion {
	return self.request.apiVersion;
}

- (NSString *)path {
	return self.request.path;
}

- (NSString *)method {
	return self.request.method;
}

- (NSString *)contentType {
	return [NSString stringWithFormat:@"multipart/form-data; boundary=%@", self.boundary];
}

- (NSString *)messageIdentifier {
	return self.request.identifier;
}

- (NSData *)payload {
	NSArray *attachments = self.request.attachments.array;
	NSString *bodyText = [[NSString alloc] initWithData:self.request.payload encoding:NSUTF8StringEncoding];

	NSMutableData *multipartEncodedData = [NSMutableData data];

	if (bodyText) {
		NSMutableString *bodyHeader = [NSMutableString string];
		[bodyHeader appendString:[NSString stringWithFormat:@"--%@\r\n", self.boundary]];
		[bodyHeader appendString:[NSString stringWithFormat:@"Content-Type: %@\r\n", @"text/plain"]];
		[bodyHeader appendString:[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", @"message"]];

		[multipartEncodedData appendData:[bodyHeader dataUsingEncoding:NSUTF8StringEncoding]];
		[multipartEncodedData appendData:[bodyText dataUsingEncoding:NSUTF8StringEncoding]];
	}

	for (ApptentiveSerialRequestAttachment *attachment in attachments) {
		NSString *boundaryString = [NSString stringWithFormat:@"\r\n--%@\r\n", self.boundary];
		[multipartEncodedData appendData:[boundaryString dataUsingEncoding:NSUTF8StringEncoding]];

		NSMutableString *multipartHeader = [NSMutableString string];
		[multipartHeader appendString:[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"%@\"\r\n", @"file[]", attachment.name]];
		[multipartHeader appendString:[NSString stringWithFormat:@"Content-Type: %@\r\n", attachment.mimeType]];
		[multipartHeader appendString:@"Content-Transfer-Encoding: binary\r\n\r\n"];

		[multipartEncodedData appendData:[multipartHeader dataUsingEncoding:NSUTF8StringEncoding]];
		[multipartEncodedData appendData:attachment.fileData];
	}

	NSString *finalBoundary = [NSString stringWithFormat:@"\r\n--%@--\r\n", self.boundary];
	[multipartEncodedData appendData:[finalBoundary dataUsingEncoding:NSUTF8StringEncoding]];

	return multipartEncodedData;
}

@end
