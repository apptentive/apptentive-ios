//
//  ApptentiveRequestOperation.h
//  ApptentiveConnect
//
//  Created by Frank Schmitt on 12/14/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol ApptentiveRequestOperationDelegate, ApptentiveRequestOperationDataSource;

@interface ApptentiveRequestOperation : NSOperation

@property (readonly, nonatomic) NSURLRequest *request;
@property (readonly, nonatomic) NSURLSessionDataTask *task;
@property (readonly, nonatomic) NSTimeInterval cacheLifetime;
@property (readonly, nonatomic) NSObject *responseObject;

- (instancetype)initWithURLRequest:(NSURLRequest *)request delegate:(id<ApptentiveRequestOperationDelegate>)delegate dataSource:(id<ApptentiveRequestOperationDataSource>)dataSource;
- (instancetype)initWithPath:(NSString *)path method:(NSString *)method payload:(NSDictionary *)payload delegate:(id<ApptentiveRequestOperationDelegate>)delegate dataSource:(id<ApptentiveRequestOperationDataSource>)dataSource;
- (instancetype)initWithPath:(NSString *)path method:(NSString *)method payloadData:(NSData *)payloadData delegate:(id<ApptentiveRequestOperationDelegate>)delegate dataSource:(id<ApptentiveRequestOperationDataSource>)dataSource;

@property (readonly, weak, nonatomic) id<ApptentiveRequestOperationDelegate> delegate;
@property (readonly, weak, nonatomic) id<ApptentiveRequestOperationDataSource> dataSource;

- (void)processNetworkError:(NSError *)error __attribute__((objc_requires_super));
- (void)processHTTPError:(NSError *)error withResponse:(NSHTTPURLResponse *)response __attribute__((objc_requires_super));
- (void)processResponse:(NSHTTPURLResponse *)response withObject:(NSObject *)responseObject __attribute__((objc_requires_super));
- (void)retryTaskWithError:(NSError *)error __attribute__((objc_requires_super));

@end

@protocol ApptentiveRequestOperationDelegate <NSObject>
@optional
- (void)requestOperationDidStart:(ApptentiveRequestOperation *)operation;
- (void)requestOperationWillRetry:(ApptentiveRequestOperation *)operation withError:(NSError *)error;
- (void)requestOperationDidFinish:(ApptentiveRequestOperation *)operation;
- (void)requestOperation:(ApptentiveRequestOperation *)operation didFailWithError:(NSError *)error;

@end

@protocol ApptentiveRequestOperationDataSource <NSObject>

@property (readonly, nonatomic) NSURL *baseURL;
@property (readonly, nonatomic) NSURLSession *URLSession;
@property (readonly, nonatomic) NSTimeInterval backoffDelay;

- (void)increaseBackoffDelay;
- (void)resetBackoffDelay;

@end
