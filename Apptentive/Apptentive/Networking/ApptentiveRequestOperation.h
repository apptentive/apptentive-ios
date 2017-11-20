//
//  ApptentiveRequestOperation.h
//  Apptentive
//
//  Created by Frank Schmitt on 12/14/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveRequestProtocol.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ApptentiveRequestOperationDataSource;
@class ApptentiveRequestOperationCallback;

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

/**
 The HTTP request that the operation will make.
 */
@property (readonly, nonatomic) NSURLRequest *URLRequest;

/**
 The data task used to make the HTTP request.
 */
@property (readonly, nullable, nonatomic) NSURLSessionDataTask *task;

/**
 The number of seconds for which the response should be considered up-to-date.
 */
@property (readonly, nonatomic) NSTimeInterval cacheLifetime;

/**
 The object decoded from the response JSON, if any.
 */
@property (readonly, nullable, nonatomic) NSObject *responseObject;

/**
 The raw response data, if any.
 */
@property (readonly, nullable, nonatomic) NSData *responseData;

/**
 The ApptentiveRequest-implementing object corresponding to this operation.
 */
@property (strong, nonatomic) id<ApptentiveRequest> request;

/**
 An object that the request operation will communicate its status to.
 */
@property (strong, nullable, nonatomic) ApptentiveRequestOperationCallback *delegate;

/**
 An object that the request operation will use to obtain additional data
 required to make or retry the request.
 */
@property (readonly, weak, nonatomic) id<ApptentiveRequestOperationDataSource> dataSource;

/**
 Initializes a request operation with the specified URL Request.

 @param URLRequest The URL request to perform.
 @param delegate The delegate that the operation will communicate with.
 @param dataSource The data source that the operation will use
 @return The newly-initialized operation.
 */
- (instancetype)initWithURLRequest:(NSURLRequest *)URLRequest delegate:(ApptentiveRequestOperationCallback *)delegate dataSource:(id<ApptentiveRequestOperationDataSource>)dataSource;

#pragma mark - Subclassing

- (void)processNetworkError:(NSError *)error __attribute__((objc_requires_super));
- (void)processHTTPError:(NSError *)error withResponse:(NSHTTPURLResponse *)response responseData:(NSData *)responseData __attribute__((objc_requires_super));
- (void)processResponse:(NSHTTPURLResponse *)response withObject:(nullable NSObject *)responseObject __attribute__((objc_requires_super));
- (void)retryTaskWithError:(nullable NSError *)error __attribute__((objc_requires_super));
- (void)completeOperation __attribute__((objc_requires_super));

@end

/**
 The `ApptentiveRequestOperationDataSource` protocol specifies how a request
 operation can obtain additional data needed to make and retry requests.
 */
@protocol ApptentiveRequestOperationDataSource <NSObject>

/**
 The `NSURLSession` object that should be used to create the HTTP request.
 */
@property (readonly, nonatomic) NSURLSession *URLSession;

/**
 The number of seconds the operation should wait before retrying a request.
 */
@property (readonly, nonatomic) NSTimeInterval backoffDelay;

/**
 Indicates that the data source should increase the backoff delay because the
 previous request encountered a retry-able error.
 */
- (void)increaseBackoffDelay;

/**
 Indicates taht the data source should reset its backoff delay because a request
 succeeded.
 */
- (void)resetBackoffDelay;

@end


@interface ApptentiveRequestOperationCallback : NSObject

@property (copy, nonatomic) void (^operationStartCallback)(ApptentiveRequestOperation *operation);
@property (copy, nonatomic) void (^operationFinishCallback)(ApptentiveRequestOperation *operation);
@property (copy, nonatomic) void (^operationRetryCallback)(ApptentiveRequestOperation *operation, NSError *error);
@property (copy, nonatomic) void (^operationFailCallback)(ApptentiveRequestOperation *operation, NSError *error);

/**
 Indicates that the request operation's request has started.
 
 @param operation The request operation.
 */
- (void)requestOperationDidStart:(ApptentiveRequestOperation *)operation;


/**
 Indicates that the request operation's request has encountered a retry-able
 error.
 
 @param operation The request operation.
 @param error The error that the request encountered.
 */
- (void)requestOperationWillRetry:(ApptentiveRequestOperation *)operation withError:(nullable NSError *)error;

/**
 Indicates that the request operation's request has succeeded.
 
 @param operation The request operation.
 */
- (void)requestOperationDidFinish:(ApptentiveRequestOperation *)operation;

/**
 Indicates that the request operation's request has encountered an unrecoverable
 error.
 
 @discussion The only type of error that is considered unrecoverable is a 400-
 series error indicating that the client is incapable of submitting a valid
 request for this data.
 
 @param operation The request operation.
 @param error The error that the request encountered.
 */
- (void)requestOperation:(ApptentiveRequestOperation *)operation didFailWithError:(nullable NSError *)error;

@end

NS_ASSUME_NONNULL_END
