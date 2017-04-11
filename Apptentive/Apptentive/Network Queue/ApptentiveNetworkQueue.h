//
//  ApptentiveNetworkQueue.h
//  Apptentive
//
//  Created by Frank Schmitt on 12/14/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ApptentiveRequestOperation.h"

/**
 The `ApptentiveNetworkQueue` is an `NSOperationQueue` subclass intended to
 manage a series of `ApptentiveRequestOperation` instances. It is initialized
 with a base URL, OAuth token, SDK version, and platform string (the latter two
 are used to construct a user agent string.

 By conforming to the `ApptentiveRequestOperationDataSource` protocol, the
 queue can provide its operations with the a URL session and the base URL
 to use to construct requests.

 It also supports exponential backoff of failing network requests.
 The `-increaseBackoffDelay` is called when a temporary failure is encountered,
 and the delay can be reset when network status changes or a request succeeds.
 */
@interface ApptentiveNetworkQueue : NSOperationQueue <ApptentiveRequestOperationDataSource, NSURLSessionDataDelegate>


/**
 Initializes a new network queu with the specified parameters.

 @param baseURL The URL on which to base request URLs.
 @param SDKVersion The current SDK version (used to generate the user agent
 header).
 @param platform The current platform (used to generate the user agent header).
 @return The newly-initialized network queue.
 */
- (instancetype)initWithBaseURL:(NSURL *)baseURL SDKVersion:(NSString *)SDKVersion platform:(NSString *)platform;

/**
 The SDK version used to initialize the queue.
 */
@property (readonly, nonatomic) NSString *SDKVersion;

/**
 The platform string used to initialize the queue.
 */
@property (readonly, nonatomic) NSString *platform;

@end
