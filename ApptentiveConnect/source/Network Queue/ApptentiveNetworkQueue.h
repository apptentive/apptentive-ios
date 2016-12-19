//
//  ApptentiveNetworkQueue.h
//  ApptentiveConnect
//
//  Created by Frank Schmitt on 12/14/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ApptentiveRequestOperation.h"

@interface ApptentiveNetworkQueue : NSOperationQueue <ApptentiveRequestOperationDataSource, NSURLSessionDataDelegate>

- (instancetype)initWithBaseURL:(NSURL *)baseURL token:(NSString *)token SDKVersion:(NSString *)SDKVersion platform:(NSString *)platform;

@property (copy, nonatomic) NSString *token;
@property (readonly, nonatomic) NSString *SDKVersion;
@property (readonly, nonatomic) NSString *platform;

@property (readonly, nonatomic) NSURL *baseURL;
@property (readonly, nonatomic) NSURLSession *URLSession;
@property (readonly, nonatomic) NSTimeInterval backoffDelay;

- (void)increaseBackoffDelay;
- (void)resetBackoffDelay;

@end
