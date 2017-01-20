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

/**
 Creates a serial request operation with the specified request info and
 delegate.

 @param requestInfo The request info to use when creating the operation.
 @param delegate The delegate with which the operation should communicate.
 @return The newly-created operation.
 */
+ (instancetype)operationWithRequestInfo:(ApptentiveSerialRequest *)requestInfo delegate:(id<ApptentiveRequestOperationDelegate, ApptentiveRequestOperationDataSource>)delegate;

/**
 The request info object associated with the operation. Primarily used to 
 delete the request information when the operation completes.
 */
@property (readonly, nonatomic) ApptentiveSerialRequest *requestInfo;

@end
