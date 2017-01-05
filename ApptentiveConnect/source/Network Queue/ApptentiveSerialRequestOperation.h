//
//  ApptentiveQueuedRequestOperation.h
//  ApptentiveConnect
//
//  Created by Frank Schmitt on 12/14/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveRequestOperation.h"

@class ApptentiveSerialRequest;

@interface ApptentiveSerialRequestOperation : ApptentiveRequestOperation

+ (instancetype)operationWithRequestInfo:(ApptentiveSerialRequest *)requestInfo delegate:(id<ApptentiveRequestOperationDelegate, ApptentiveRequestOperationDataSource>)delegate;

- (instancetype)initWithRequestInfo:(ApptentiveSerialRequest *)requestInfo delegate:(id<ApptentiveRequestOperationDelegate, ApptentiveRequestOperationDataSource>)delegate;

@property (readonly, nonatomic) ApptentiveSerialRequest *requestInfo;

@end
