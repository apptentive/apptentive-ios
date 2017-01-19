//
//  ApptentiveSerialNetworkQueue.h
//  ApptentiveConnect
//
//  Created by Frank Schmitt on 12/14/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveNetworkQueue.h"
#import <CoreData/CoreData.h>
#import "ApptentiveSerialRequestOperation.h"
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, ApptentiveQueueStatus) {
	ApptentiveQueueStatusUnknown,
	ApptentiveQueueStatusError,
	ApptentiveQueueStatusGroovy
};

/**
 The `ApptentiveSerialNetworkQueue` is subclass that loads a series of 
 `ApptentiveSerialRequest` instances from a Core Data managed object context. 
 (It makes use of a private child managed object context to allow processing off
 of the main queue.)

 These requests are then placed on the queue and executed in order (the
 concurrent operation count is set to one). When a request completes, the
 Core Data entry is deleted.

 When all requests in a particular batch (that is, all of the requests that
 exist in the context when `-resume` is called) complete, the context is saved,
 followed by its parent context being saved.

 The class implements the `NSURLSessionDelegate` protocol in order to track the
 progress of message send tasks, which it uses to update the 
 `messageSendProgress` and `messageTaskCount` properties. The former is used to
 indicate the progress of message send requests, and the latter is used to
 determine whether to show or hide a progress bar. Both properties are KVO
 compliant.

 The queue also features a `status` property that is KVO compliant and will
 change based on the completion or failure status of the most recent request
 in the queue. Because of the strict ordering of the queue, this is a better
 indication of message sending progress or failure than the individual message
 send requests, since they may be stuck in the queue behind another failing
 request.

 Finally, for iOS, it supports a background task identifier so that the save
 operation can complete as a background task after the app is moved to the
 background.
 */
@interface ApptentiveSerialNetworkQueue : ApptentiveNetworkQueue <ApptentiveRequestOperationDelegate, NSURLSessionDelegate, NSURLSessionDataDelegate>

- (instancetype)initWithBaseURL:(NSURL *)baseURL token:(NSString *)token SDKVersion:(NSString *)SDKVersion platform:(NSString *)platform parentManagedObjectContext:(NSManagedObjectContext *)parentManagedObjectContext;

- (void)resume;

@property (readonly, nonatomic) NSNumber *messageSendProgress;
@property (readonly, nonatomic) NSInteger messageTaskCount;
@property (readonly, nonatomic) ApptentiveQueueStatus status;
@property (assign, nonatomic) UIBackgroundTaskIdentifier backgroundTaskIdentifier;

@end
