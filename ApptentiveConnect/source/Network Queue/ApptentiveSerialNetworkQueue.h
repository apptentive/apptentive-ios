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

typedef NS_ENUM(NSInteger, ApptentiveQueueStatus) {
	ApptentiveQueueStatusUnknown,
	ApptentiveQueueStatusError,
	ApptentiveQueueStatusGroovy
};

@interface ApptentiveSerialNetworkQueue : ApptentiveNetworkQueue <ApptentiveRequestOperationDelegate, NSURLSessionDelegate, NSURLSessionDataDelegate>

- (instancetype)initWithBaseURL:(NSURL *)baseURL token:(NSString *)token SDKVersion:(NSString *)SDKVersion platform:(NSString *)platform parentManagedObjectContext:(NSManagedObjectContext *)parentManagedObjectContext;

- (void)resumeWithDependency:(NSOperation *)dependency;

@property (readonly, nonatomic) NSNumber *messageSendProgress;
@property (readonly, nonatomic) NSInteger messageTaskCount;
@property (readonly, nonatomic) ApptentiveQueueStatus status;

@end
