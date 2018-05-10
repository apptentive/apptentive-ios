//
//  ApptentiveRequestOperation.m
//  Apptentive
//
//  Created by Frank Schmitt on 12/14/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveRequestOperation.h"
#import "ApptentiveBackend.h"
#import "ApptentiveJSONSerialization.h"
#import "ApptentiveJSONSerialization.h"
#import "ApptentiveRequestProtocol.h"
#import "ApptentiveSafeCollections.h"
#import "ApptentiveSerialRequest.h"
#import "ApptentiveRetryPolicy.h"

NS_ASSUME_NONNULL_BEGIN


@interface ApptentiveRequestOperation () {
	NSDate *_startDate;
}

@property (assign, nonatomic) BOOL wasCompleted;
@property (readonly, nonatomic) NSTimeInterval duration;

@end

NSErrorDomain const ApptentiveHTTPErrorDomain = @"com.apptentive.http";


@implementation ApptentiveRequestOperation

- (instancetype)initWithURLRequest:(NSURLRequest *)URLRequest delegate:(ApptentiveRequestOperationCallback *)delegate dataSource:(id<ApptentiveRequestOperationDataSource>)dataSource {
	self = [super init];

	if (self) {
		_URLRequest = URLRequest;
		_delegate = delegate;
		_dataSource = dataSource;
	}

	return self;
}

- (BOOL)isExecuting {
	@synchronized(self) {
		return self.task != nil;
	}
}

- (BOOL)isFinished {
	@synchronized(self) {
		return self.wasCompleted || self.cancelled;
	}
}

- (void)main {
	[self startTask];
}

- (void)startTask {
	@synchronized(self) {
		_startDate = [[NSDate alloc] init];

		if (self.cancelled) {
			return;
		}

		[self willChangeValueForKey:@"isExecuting"];

		_task = [self.dataSource.URLSession dataTaskWithRequest:self.URLRequest completionHandler:^(NSData *_Nullable data, NSURLResponse *_Nullable response, NSError *_Nullable error) {
			if (self.cancelled || error.code == NSURLErrorCancelled) {
				[self completeOperation];
				return;
			} else if (!response) {
				[self processNetworkError:error];
			} else {
				NSHTTPURLResponse *URLResponse = (NSHTTPURLResponse *)response;
				self->_responseData = data; // Store "raw" response data to access from the callback

				if ([[ApptentiveClient okStatusCodes] containsIndex:URLResponse.statusCode]) {
					NSObject *responseObject = nil;

					if (URLResponse.statusCode != 204) { // "No Content"
						responseObject = [ApptentiveJSONSerialization JSONObjectWithData:data error:&error];

						if (responseObject == nil) { // Decoding error
							[self processHTTPError:error withResponse:URLResponse responseData:data];
						}
					}

					[self processResponse:URLResponse withObject:responseObject];
				} else {
					[self processHTTPError:error withResponse:URLResponse responseData:data];
				}

				// check if request failed due to an authentication failure
				if (URLResponse.statusCode == 401) {
					[self processAuthenticationFailureResponseData:data];
				}
			}
		}];

		[self.task resume];
		[self didChangeValueForKey:@"isExecuting"];
		ApptentiveLogDebug(ApptentiveLogTagNetwork, @"%@ %@ started.", self.URLRequest.HTTPMethod, self.URLRequest.URL.absoluteString);
		ApptentiveLogVerbose(ApptentiveLogTagNetwork, @"Headers: %@%@", ApptentiveHideKeysIfSanitized(self.URLRequest.allHTTPHeaderFields, @[@"Authorization"]), self.URLRequest.HTTPBody.length > 0 ? [NSString stringWithFormat:@"\n-----------PAYLOAD BEGIN-----------\n%@\n-----------PAYLOAD END-----------", ApptentiveHideIfSanitized([[NSString alloc] initWithData:self.URLRequest.HTTPBody encoding:NSUTF8StringEncoding])] : @"");

		[self.dataSource.URLSession.delegateQueue addOperationWithBlock:^{
		  [self.delegate requestOperationDidStart:self];
		}];
	}
}

- (void)cancel {
	@synchronized(self) {
		[super cancel];
		[self.task cancel];
	}
}

- (void)processResponse:(NSHTTPURLResponse *)response withObject:(nullable NSObject *)responseObject {
	_cacheLifetime = [self maxAgeFromResponse:response];
	_responseObject = responseObject;

	ApptentiveLogDebug(ApptentiveLogTagNetwork, @"%@ %@ finished successfully (took %g sec).", self.URLRequest.HTTPMethod, self.URLRequest.URL.absoluteString, self.duration);

	ApptentiveLogVerbose(ApptentiveLogTagNetwork, @"Response object:\n%@.", ApptentiveHideIfSanitized(responseObject ?: @""));

	[self.delegate requestOperationDidFinish:self];

	[self.dataSource.retryPolicy resetRetryDelay];

	[self completeOperation];
}

- (void)processNetworkError:(NSError *)error {
	[self retryTaskWithError:error];
}

- (void)processHTTPError:(NSError *)error withResponse:(NSHTTPURLResponse *)response responseData:(NSData *)responseData {
	BOOL shouldRetry = [self.dataSource.retryPolicy shouldRetryRequestWithStatusCode:response.statusCode];
	NSString *HTTPErrorTitle;
	NSString *HTTPErrorMessage = responseData == nil ? @"" : [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];

	if ([[ApptentiveClient serverErrorStatusCodes] containsIndex:response.statusCode]) {
		HTTPErrorTitle = @"Server error";
	} else if ([[ApptentiveClient clientErrorStatusCodes] containsIndex:response.statusCode]) {
		HTTPErrorTitle = @"Client error";
	}

	if (error == nil && HTTPErrorTitle != nil) {
		NSDictionary *userInfo = @{
			NSLocalizedDescriptionKey: HTTPErrorTitle,
			NSLocalizedFailureReasonErrorKey: HTTPErrorMessage,
			NSURLErrorFailingURLErrorKey: ApptentiveCollectionValue(self.URLRequest.URL)
		};
		error = [NSError errorWithDomain:ApptentiveHTTPErrorDomain code:response.statusCode userInfo:userInfo];
	}

	if (shouldRetry) {
		[self retryTaskWithError:error];
	} else {
		[self finishWithError:error];
	}
}

- (void)retryTaskWithError:(nullable NSError *)error {
	if (error != nil) {
		ApptentiveLogWarning(ApptentiveLogTagNetwork, @"%@ %@ failed with error (%@).", self.URLRequest.HTTPMethod, self.URLRequest.URL.absoluteString, error);
	}

	[self.dataSource.retryPolicy increaseRetryDelay];
	NSTimeInterval retryDelay = self.dataSource.retryPolicy.retryDelay;

	ApptentiveLogInfo(@"%@ %@ will retry in %f seconds.", self.URLRequest.HTTPMethod, self.URLRequest.URL.absoluteString, retryDelay);

	[self.delegate requestOperationWillRetry:self withError:error];

	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(retryDelay * NSEC_PER_SEC)), dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0), ^{
	  [self startTask];
	});
}

- (void)processAuthenticationFailureResponseData:(NSData *)data {
	NSError *error;
	id jsonObject = [ApptentiveJSONSerialization JSONObjectWithData:data error:&error];
	if (error) {
		ApptentiveLogError(ApptentiveLogTagNetwork, @"Error while parsing JSON (%@).", error);
		return;
	}

	if (![jsonObject isKindOfClass:[NSDictionary class]]) {
		ApptentiveLogError(ApptentiveLogTagNetwork, @"Unexpected JSON object: %@", ApptentiveHideIfSanitized(jsonObject));
		return;
	}

	NSString *conversationIdentifier = self.request.conversationIdentifier ?: @"NO CONVERSATION";
	NSString *errorType = ApptentiveDictionaryGetString(jsonObject, @"error_type") ?: @"UNKNOWN";
	NSString *errorMessage = ApptentiveDictionaryGetString(jsonObject, @"error") ?: @"Unknown error";

	[[NSNotificationCenter defaultCenter] postNotificationName:ApptentiveAuthenticationDidFailNotification
														object:nil
													  userInfo:@{
														  ApptentiveAuthenticationDidFailNotificationKeyErrorType: errorType,
														  ApptentiveAuthenticationDidFailNotificationKeyErrorMessage: errorMessage,
														  ApptentiveAuthenticationDidFailNotificationKeyConversationIdentifier: conversationIdentifier
													  }];
}

- (void)completeOperation {
	@synchronized(self) {
		[self willChangeValueForKey:@"isFinished"];
		[self willChangeValueForKey:@"isExecuting"];
		_task = nil;
		self.wasCompleted = YES;
		[self didChangeValueForKey:@"isFinished"];
		[self didChangeValueForKey:@"isExecuting"];
	}
}

- (void)finishWithError:(NSError *)error {
	ApptentiveLogError(ApptentiveLogTagNetwork, @"%@ %@ failed with error after %g sec (%@). Not retrying.", self.URLRequest.HTTPMethod, self.URLRequest.URL.absoluteString, self.duration, error);

	[self.delegate requestOperation:self didFailWithError:error];

	[self completeOperation];
}

- (NSTimeInterval)maxAgeFromResponse:(NSURLResponse *)response {
	NSString *cacheControl = [((NSHTTPURLResponse *)response).allHeaderFields valueForKey:@"Cache-Control"];

	if (cacheControl == nil || [cacheControl rangeOfString:@"max-age"].location == NSNotFound) {
		return 0;
	}

	NSTimeInterval maxAge = 0;
	NSScanner *scanner = [NSScanner scannerWithString:[cacheControl lowercaseString]];
	[scanner scanUpToString:@"max-age" intoString:NULL];
	if ([scanner scanString:@"max-age" intoString:NULL] && [scanner scanString:@"=" intoString:NULL]) {
		if (![scanner scanDouble:&maxAge]) {
			maxAge = 0;
		}
	}

	return maxAge;
}

- (NSTimeInterval)duration {
	return -[_startDate timeIntervalSinceNow];
}

- (nullable NSString *)name {
	return [NSString stringWithFormat:@"Request Operation (%@ %@)", self.URLRequest.HTTPMethod, self.URLRequest.URL.absoluteString];
}

@end


@implementation ApptentiveRequestOperationCallback

#pragma mark - ApptentiveRequestOperationDelegate implementation

- (void)requestOperationDidStart:(ApptentiveRequestOperation *)operation {
	if (self.operationStartCallback) {
		self.operationStartCallback(operation);
	}
}

- (void)requestOperationDidFinish:(ApptentiveRequestOperation *)operation {
	if (self.operationFinishCallback) {
		self.operationFinishCallback(operation);
	}
}

- (void)requestOperationWillRetry:(ApptentiveRequestOperation *)operation withError:(nullable NSError *)error {
	if (self.operationRetryCallback) {
		self.operationRetryCallback(operation, error);
	}
}

- (void)requestOperation:(ApptentiveRequestOperation *)operation didFailWithError:(nullable NSError *)error {
	if (self.operationFailCallback) {
		self.operationFailCallback(operation, error);
	}
}

@end

NS_ASSUME_NONNULL_END
