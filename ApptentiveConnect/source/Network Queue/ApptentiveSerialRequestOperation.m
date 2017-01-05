//
//  ApptentiveQueuedRequestOperation.m
//  ApptentiveConnect
//
//  Created by Frank Schmitt on 12/14/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveSerialRequestOperation.h"
#import "ApptentiveSerialRequest.h"
#import "ApptentiveSerialNetworkQueue.h"
#import "ApptentiveMessageRequestOperation.h"

@implementation ApptentiveSerialRequestOperation

+ (instancetype)operationWithRequestInfo:(ApptentiveSerialRequest *)requestInfo delegate:(id<ApptentiveRequestOperationDelegate,ApptentiveRequestOperationDataSource>)delegate  {
	if ([requestInfo.path isEqualToString:@"messages"]) {
		return [[ApptentiveMessageRequestOperation alloc] initWithRequestInfo:requestInfo delegate:delegate];
	} else {
		return [[ApptentiveSerialRequestOperation alloc] initWithRequestInfo:requestInfo delegate:delegate];
	}
}

- (instancetype)initWithRequestInfo:(ApptentiveSerialRequest *)requestInfo delegate:(id<ApptentiveRequestOperationDelegate,ApptentiveRequestOperationDataSource>)delegate {
	self = [super initWithPath:requestInfo.path method:requestInfo.method payloadData:requestInfo.payload delegate:delegate dataSource:delegate];

	if (self) {
		_requestInfo = requestInfo;
	}

	return self;
}

- (void)processResponse:(NSHTTPURLResponse *)response withObject:(NSObject *)responseObject {
	[super processResponse:response withObject:responseObject];

	[self.requestInfo.managedObjectContext performBlockAndWait:^{
		[self.requestInfo.managedObjectContext deleteObject:self.requestInfo];
	}];
}

@end
