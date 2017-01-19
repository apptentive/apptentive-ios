//
//  ApptentiveRequestOperation.h
//  ApptentiveConnect
//
//  Created by Frank Schmitt on 12/14/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol ApptentiveRequestOperationDelegate, ApptentiveRequestOperationDataSource;

extern NSErrorDomain const ApptentiveHTTPErrorDomain;


/**
 The `ApptentiveRequestOperaion` class is an `NSOperation` subclass that
 performs a network request. The operation will continue to retry until it
 completes, is cancelled, or encounters an unrecoverable error (basically, any
 HTTP error in the 400-499 range).

 `ApptentiveRequestOperation` instances can be initialized with an
 `NSURLRequest` object, or with a convenience initializer that constructs the
 request based on values from the data source along with a path, method and
 payload dictionary that will be encoded as JSON.

 Finally there is a convenience initializer intended for use with
 `ApptentiveSerialRequest` objects, whose payload is already encoded and whose
 API version may differ from the current one (when migrating an app from an SDK
 that uses an older API version).

 Delegate methods (in the `ApptentiveRequestOperationDelegate` protocol) are
 called when the request operation starts, when it retries, when it finishes, 
 and when an unrecoverable error is encountered.
 */
@interface ApptentiveRequestOperation : NSOperation

@property (readonly, nonatomic) NSURLRequest *request;
@property (readonly, nonatomic) NSURLSessionDataTask *task;
@property (readonly, nonatomic) NSTimeInterval cacheLifetime;
@property (readonly, nonatomic) NSObject *responseObject;

+ (NSString *)APIVersion;

- (instancetype)initWithURLRequest:(NSURLRequest *)request delegate:(id<ApptentiveRequestOperationDelegate>)delegate dataSource:(id<ApptentiveRequestOperationDataSource>)dataSource;
- (instancetype)initWithPath:(NSString *)path method:(NSString *)method payload:(NSDictionary *)payload delegate:(id<ApptentiveRequestOperationDelegate>)delegate dataSource:(id<ApptentiveRequestOperationDataSource>)dataSource;
- (instancetype)initWithPath:(NSString *)path method:(NSString *)method payloadData:(NSData *)payloadData APIVersion:(NSString *)APIVersion delegate:(id<ApptentiveRequestOperationDelegate>)delegate dataSource:(id<ApptentiveRequestOperationDataSource>)dataSource;

@property (readonly, weak, nonatomic) id<ApptentiveRequestOperationDelegate> delegate;
@property (readonly, weak, nonatomic) id<ApptentiveRequestOperationDataSource> dataSource;

- (void)processNetworkError:(NSError *)error __attribute__((objc_requires_super));
- (void)processHTTPError:(NSError *)error withResponse:(NSHTTPURLResponse *)response responseData:(NSData *)responseData __attribute__((objc_requires_super));
- (void)processResponse:(NSHTTPURLResponse *)response withObject:(NSObject *)responseObject __attribute__((objc_requires_super));
- (void)retryTaskWithError:(NSError *)error __attribute__((objc_requires_super));

- (void)completeOperation __attribute__((objc_requires_super));

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
