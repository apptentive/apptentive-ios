//
//  ApptentiveMessageRequestOperation.m
//  ApptentiveConnect
//
//  Created by Frank Schmitt on 12/16/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveMessageRequestOperation.h"
#import "ApptentiveSerialRequest.h"
#import "ApptentiveSerialRequestAttachment.h"
#import "ApptentiveUtilities.h"


@implementation ApptentiveMessageRequestOperation

+ (NSURLRequest *)requestForSendingRequestInfo:(ApptentiveSerialRequest *)requestInfo baseURL:(NSURL *)baseURL {
	NSArray *attachments = requestInfo.attachments.array;
	NSString *bodyText = [[NSString alloc] initWithData:requestInfo.payload encoding:NSUTF8StringEncoding];
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:requestInfo.path relativeToURL:baseURL]];
	request.HTTPMethod = requestInfo.method;

	NSString *boundary = [ApptentiveUtilities randomStringOfLength:20];
	NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary];
	[request setValue:contentType forHTTPHeaderField:@"Content-Type"];

	NSMutableData *multipartEncodedData = [NSMutableData data];
	NSMutableString *debugString = [NSMutableString string];

	for (NSString *key in request.allHTTPHeaderFields) {
		[debugString appendFormat:@"%@: %@\n", key, [request.allHTTPHeaderFields objectForKey:key]];
	}
	[debugString appendString:@"\n"];

	if (bodyText) {
		NSMutableString *bodyHeader = [NSMutableString string];
		[bodyHeader appendString:[NSString stringWithFormat:@"--%@\r\n", boundary]];
		[bodyHeader appendString:[NSString stringWithFormat:@"Content-Type: %@\r\n", @"text/plain"]];
		[bodyHeader appendString:[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", @"message"]];
		[debugString appendString:bodyHeader];

		[multipartEncodedData appendData:[bodyHeader dataUsingEncoding:NSUTF8StringEncoding]];
		[multipartEncodedData appendData:[bodyText dataUsingEncoding:NSUTF8StringEncoding]];
		[debugString appendString:bodyText];
	}

	for (ApptentiveSerialRequestAttachment *attachment in attachments) {
		NSString *boundaryString = [NSString stringWithFormat:@"\r\n--%@\r\n", boundary];
		[multipartEncodedData appendData:[boundaryString dataUsingEncoding:NSUTF8StringEncoding]];
		[debugString appendString:boundaryString];

		NSMutableString *multipartHeader = [NSMutableString string];
		[multipartHeader appendString:[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"%@\"\r\n", @"file[]", attachment.name]];
		[multipartHeader appendString:[NSString stringWithFormat:@"Content-Type: %@\r\n", attachment.mimeType]];
		[multipartHeader appendString:@"Content-Transfer-Encoding: binary\r\n\r\n"];
		[debugString appendString:multipartHeader];

		[multipartEncodedData appendData:[multipartHeader dataUsingEncoding:NSUTF8StringEncoding]];
		[multipartEncodedData appendData:attachment.fileData];
		[debugString appendFormat:@"<NSData of length: %lu>", (unsigned long)[attachment.fileData length]];
	}

	NSString *finalBoundary = [NSString stringWithFormat:@"\r\n--%@--\r\n", boundary];
	[multipartEncodedData appendData:[finalBoundary dataUsingEncoding:NSUTF8StringEncoding]];
	[debugString appendString:finalBoundary];

	//NSLog(@"\n%@", debugString);

	request.HTTPBody = multipartEncodedData;

	// Debugging helpers:
	/*
	 NSLog(@"wtf parameters: %@", parameters);
	 NSLog(@"-length: %d", [multipartEncodedData length]);
	 NSLog(@"-data: %@", [NSString stringWithUTF8String:[multipartEncodedData bytes]]);
	 */
	return request;
}

- (instancetype)initWithRequestInfo:(ApptentiveSerialRequest *)requestInfo delegate:(id<ApptentiveRequestOperationDelegate,ApptentiveRequestOperationDataSource>)delegate {
	NSURLRequest *request = [[self class] requestForSendingRequestInfo:requestInfo baseURL:delegate.baseURL];

	self = [super initWithURLRequest:request delegate:delegate dataSource:delegate];

	if (self) {
		_messageRequestInfo = requestInfo;
	}

	return self;
}

- (ApptentiveSerialRequest *)requestInfo {
	return self.messageRequestInfo;
}

- (void)processResponse:(NSHTTPURLResponse *)response withObject:(NSObject *)responseObject {
	[super processResponse:response withObject:responseObject];

	[self setMessagePendingState:ATPendingMessageStateConfirmed];
}

- (void)processNetworkError:(NSError *)error {
	[super processNetworkError:error];

	[self setMessagePendingState:ATPendingMessageStateError];
}

- (void)processHTTPError:(NSError *)error withResponse:(NSHTTPURLResponse *)response {
	[super processHTTPError:error withResponse:response];

	[self setMessagePendingState:ATPendingMessageStateError];
}

- (void)setMessagePendingState:(ATPendingMessageState)pendingState {
	NSManagedObjectContext *context = self.requestInfo.managedObjectContext;

	[context performBlockAndWait:^{
		NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"ATMessage"];
		fetchRequest.predicate = [NSPredicate predicateWithFormat:@"pendingMessageID = %@", self.messageRequestInfo.identifier];

		NSError *error;
		NSArray *results = [context executeFetchRequest:fetchRequest error:&error];

		if (results.count == 1) {
			((ApptentiveMessage *)results.firstObject).pendingState = @(pendingState);
		} else {
			ApptentiveLogError(@"Unable to identify sent message: %@", error);
		}

		if (![context save:&error]) {
			ApptentiveLogError(@"Unable to save pending state of message: %@", error);
		}
	}];
}


@end
