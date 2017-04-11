//
//  ApptentiveSerialNetworkQueue.h
//  Apptentive
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

/**
 Initializes a new serial network queue with the specified parameters.

 @param baseURL The URL on which to base HTTP requests.
 @param SDKVersion The SDK version (used to generate the user agent header).
 @param platform The platform string (used to generate the user agent header).
 @param parentManagedObjectContext The managed object context to use as a parent
 when creating a private managed object context for reading new request
 information from Core Data.
 @return The newly-initialzed serial queue.
 */
- (instancetype)initWithBaseURL:(NSURL *)baseURL SDKVersion:(NSString *)SDKVersion platform:(NSString *)platform parentManagedObjectContext:(NSManagedObjectContext *)parentManagedObjectContext;

/**
 Instructs the queue to read any pending request information from Core Data and
 create an `ApptentiveSerialRequestOperation` instance for each of them. These
 operations are then enqueued, followed by an operation that saves the private
 context to its parent, and saves the parent context to disk.
 */
- (void)resume;


/**
 A number representing the average progress across all message operations in the
 queue.
 */
@property (readonly, nonatomic) NSNumber *messageSendProgress;

/**
 A count representing the number of message operations in the queue.
 */
@property (readonly, nonatomic) NSInteger messageTaskCount;

/**
 The status (success or failure) of the most recently-sent request in the queue.
 */
@property (readonly, nonatomic) ApptentiveQueueStatus status;

/**
 A background task identifier, used on iOS to complete the parent context save
 operation when an app is closed.
 */
@property (assign, nonatomic) UIBackgroundTaskIdentifier backgroundTaskIdentifier;

@end
