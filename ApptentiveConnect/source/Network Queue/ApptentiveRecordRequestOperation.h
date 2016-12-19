//
//  ApptentiveRecordRequestOperation.h
//  ApptentiveConnect
//
//  Created by Frank Schmitt on 12/14/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveRequestOperation.h"

@class ApptentiveQueuedRequest;

@interface ApptentiveRecordRequestOperation : ApptentiveRequestOperation

+ (instancetype)operationWithRequestInfo:(ApptentiveQueuedRequest *)requestInfo delegate:(id<ApptentiveRequestOperationDelegate, ApptentiveRequestOperationDataSource>)delegate;

- (instancetype)initWithRequestInfo:(ApptentiveQueuedRequest *)requestInfo delegate:(id<ApptentiveRequestOperationDelegate, ApptentiveRequestOperationDataSource>)delegate;

@property (readonly, nonatomic) ApptentiveQueuedRequest *requestInfo;

@end
