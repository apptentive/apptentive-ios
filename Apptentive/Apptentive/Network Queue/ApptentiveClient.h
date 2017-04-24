//
//  ApptentiveClient.h
//  Apptentive
//
//  Created by Frank Schmitt on 4/24/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ApptentiveRequestOperation.h"

@class ApptentiveConversation;

NS_ASSUME_NONNULL_BEGIN


@interface ApptentiveClient : NSObject <NSURLSessionDelegate, ApptentiveRequestOperationDelegate, ApptentiveRequestOperationDataSource>

@property (readonly, nonatomic) NSOperationQueue *operationQueue;
@property (readonly, nonatomic) NSURL *baseURL;
@property (strong, nullable, nonatomic) NSString *authToken;

- (instancetype)initWithBaseURL:(NSURL *)baseURL operationQueue:(NSOperationQueue *)operationQueue;

- (ApptentiveRequestOperation *)requestOperationWithRequest:(id<ApptentiveRequest>)request delegate:(id<ApptentiveRequestOperationDelegate>)delegate;

- (ApptentiveRequestOperation *)requestOperationWithRequest:(id<ApptentiveRequest>)request authToken:(NSString *)authToken delegate:(id<ApptentiveRequestOperationDelegate>)delegate;

@end

NS_ASSUME_NONNULL_END
