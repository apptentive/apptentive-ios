//
//  ApptentiveClient.h
//  Apptentive
//
//  Created by Frank Schmitt on 4/24/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ApptentiveRequestOperation.h"
#import "ApptentiveMessage.h"

@class ApptentiveConversation;

NS_ASSUME_NONNULL_BEGIN


@interface ApptentiveClient : NSObject <NSURLSessionDelegate, ApptentiveRequestOperationDataSource>

@property (readonly, nonatomic) NSOperationQueue *operationQueue;
@property (readonly, nonatomic) NSURL *baseURL;
@property (readonly, nonatomic) NSString *appKey;
@property (readonly, nonatomic) NSString *appSignature;
@property (strong, nullable, nonatomic) NSString *authToken;

- (instancetype)initWithBaseURL:(NSURL *)baseURL appKey:(NSString *)appKey appSignature:(NSString *)appSignature;

- (ApptentiveRequestOperation *)requestOperationWithRequest:(id<ApptentiveRequest>)request delegate:(id<ApptentiveRequestOperationDelegate>)delegate;

- (ApptentiveRequestOperation *)requestOperationWithRequest:(id<ApptentiveRequest>)request authToken:(NSString *_Nullable)authToken delegate:(id<ApptentiveRequestOperationDelegate>)delegate;

@end

NS_ASSUME_NONNULL_END
