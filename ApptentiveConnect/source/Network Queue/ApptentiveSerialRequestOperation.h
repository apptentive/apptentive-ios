//
//  ApptentiveQueuedRequestOperation.h
//  ApptentiveConnect
//
//  Created by Frank Schmitt on 12/14/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveRequestOperation.h"

@class ApptentiveSerialRequest;

/**
 `ApptentiveSerialRequestOperation` is an `ApptentiveRequestOperation`
 subclass that manages deleting the `ApptentiveSerialRequest` objects
 corresponding to completed (or permanently failed) network requests.

 It also adds a convenience method for constructing a request operation based
 on the information in an `ApptentiveSerialRequest` object.
 */
@interface ApptentiveSerialRequestOperation : ApptentiveRequestOperation

+ (instancetype)operationWithRequestInfo:(ApptentiveSerialRequest *)requestInfo delegate:(id<ApptentiveRequestOperationDelegate, ApptentiveRequestOperationDataSource>)delegate;

- (instancetype)initWithRequestInfo:(ApptentiveSerialRequest *)requestInfo delegate:(id<ApptentiveRequestOperationDelegate, ApptentiveRequestOperationDataSource>)delegate;

@property (readonly, nonatomic) ApptentiveSerialRequest *requestInfo;

@end
