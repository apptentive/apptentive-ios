//
//  ATRecordRequestTask.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 3/10/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveTask.h"
#import "ApptentiveAPIRequest.h"

typedef enum {
	ATRecordRequestTaskFailedResult,
	ATRecordRequestTaskFinishedResult,
} ATRecordRequestTaskResult;

@protocol ATRequestTaskProvider;


@interface ApptentiveRecordRequestTask : ApptentiveTask <ApptentiveAPIRequestDelegate>
@property (strong, nonatomic) NSObject<ATRequestTaskProvider> *taskProvider;
@end


@protocol ATRequestTaskProvider <NSObject>
- (NSURL *)managedObjectURIRepresentationForTask:(ApptentiveRecordRequestTask *)task;
- (void)cleanupAfterTask:(ApptentiveRecordRequestTask *)task;
- (ApptentiveAPIRequest *)requestForTask:(ApptentiveRecordRequestTask *)task;
- (ATRecordRequestTaskResult)taskResultForTask:(ApptentiveRecordRequestTask *)task withRequest:(ApptentiveAPIRequest *)request withResult:(id)result;
@end
