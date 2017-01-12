//
//  ApptentiveRequestOperation.m
//  ApptentiveConnect
//
//  Created by Frank Schmitt on 12/14/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveRequestOperation.h"

@interface ApptentiveRequestOperation ()

@property (assign, nonatomic) BOOL wasCompleted;
@property (assign, nonatomic) BOOL wasCancelled;

@end

NSErrorDomain const ApptentiveHTTPErrorDomain = @"com.apptentive.http";

@implementation ApptentiveRequestOperation

+ (NSIndexSet *) okStatusCodes {
	static NSIndexSet *_okStatusCodes;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		_okStatusCodes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(200, 100)]; // 2xx status codes
	});

	return _okStatusCodes;
}

+ (NSIndexSet *) clientErrorStatusCodes {
	static NSIndexSet *_clientErrorStatusCodes;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		_clientErrorStatusCodes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(400, 100)]; // 4xx status codes

	});

	return _clientErrorStatusCodes;
}

+ (NSIndexSet *) serverErrorStatusCodes {
	static NSIndexSet *_serverErrorStatusCodes;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		_serverErrorStatusCodes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(500, 100)]; // 5xx status codes

	});

	return _serverErrorStatusCodes;
}

- (instancetype)initWithPath:(NSString *)path method:(NSString *)method payload:(NSDictionary *)payload delegate:(id<ApptentiveRequestOperationDelegate>)delegate dataSource:(id<ApptentiveRequestOperationDataSource>)dataSource {
	NSData *payloadData = nil;

	if (payload) {
		NSError *error;
		payloadData = [NSJSONSerialization dataWithJSONObject:payload options:0 error:&error];

		if (!payloadData) {
			NSLog(@"Error encoding payload: %@", error.localizedDescription);
			return nil;
		}
	}

	return [self initWithPath:path method:method payloadData:payloadData delegate:delegate dataSource:dataSource];
}

- (instancetype)initWithPath:(NSString *)path method:(NSString *)method payloadData:(NSData *)payloadData delegate:(id<ApptentiveRequestOperationDelegate>)delegate dataSource:(id<ApptentiveRequestOperationDataSource>)dataSource {
	NSURL *URL = [NSURL URLWithString:path relativeToURL:dataSource.baseURL];

	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
	request.HTTPBody = payloadData;
	request.HTTPMethod = method;
	[request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];

	return [self initWithURLRequest:request delegate:delegate dataSource:dataSource];
}

- (instancetype)initWithURLRequest:(NSURLRequest *)request delegate:(id<ApptentiveRequestOperationDelegate>)delegate dataSource:(id<ApptentiveRequestOperationDataSource>)dataSource {
	self = [super init];

	if (self) {
		_request = request;
		_delegate = delegate;
		_dataSource = dataSource;
	}

	return self;
}

- (NSString *)name {
	return self.request.URL.path;
}

- (BOOL)isExecuting {
	return self.task != nil;
}

- (BOOL)isFinished {
	return self.wasCompleted || self.wasCancelled;
}

- (BOOL)isCancelled {
	return self.wasCancelled;
}

- (void)main {
	[self startTask];
}

- (void)startTask {
	if (self.cancelled) {
		return;
	}

	[self willChangeValueForKey:@"isExecuting"];
	_task = [self.dataSource.URLSession dataTaskWithRequest:self.request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
		if (self.isCancelled) {
			return;
		} else if (!response) {
			[self processNetworkError:error];
		} else {
			NSHTTPURLResponse *URLResponse = (NSHTTPURLResponse *)response;

			if ([[[self class] okStatusCodes] containsIndex:URLResponse.statusCode]) {
				NSObject *responseObject = nil;

				if (URLResponse.statusCode != 204) { // "No Content"
					responseObject = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&error];

					if (responseObject == nil) { // Decoding error
						[self processHTTPError:error withResponse:URLResponse responseData:data];
					}
				}

				[self processResponse:URLResponse withObject:responseObject];
			} else {
				[self processHTTPError:error withResponse:URLResponse responseData:data];
			}
		}
	}];

	[self.task resume];
	[self didChangeValueForKey:@"isExecuting"];

	if ([self.delegate respondsToSelector:@selector(requestOperationDidStart:)]) {
		[self.delegate requestOperationDidStart:self];
	}
}

- (void)cancel {
	BOOL shouldFinish = self.isExecuting;

	[self willChangeValueForKey:@"isCancelled"];
	[self.task cancel];
	[self didChangeValueForKey:@"isCancelled"];

	if (shouldFinish) {
		[self willChangeValueForKey:@"isFinished"];
		_wasCompleted = YES;
		[self didChangeValueForKey:@"isFinished"];
	}
}

- (void)processResponse:(NSHTTPURLResponse *)response withObject:(NSObject *)responseObject {
	_cacheLifetime = [self maxAgeFromResponse:response];
	_responseObject = responseObject;

	if ([self.delegate respondsToSelector:@selector(requestOperationDidFinish:)]) {
		[self.delegate requestOperationDidFinish:self];
	}
	
	[self.dataSource resetBackoffDelay];

	[self completeOperation];
}

- (void)processNetworkError:(NSError *)error {
	[self retryTaskWithError:error];
}

- (void)processHTTPError:(NSError *)error withResponse:(NSHTTPURLResponse *)response responseData:(NSData *)responseData {
	BOOL shouldRetry = YES;
	NSString *HTTPErrorTitle;
	NSString *HTTPErrorMessage = responseData == nil ? @"" : [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];

	if ([[[self class] serverErrorStatusCodes] containsIndex:response.statusCode]) {
		HTTPErrorTitle = @"Server error";
	} else if ([[[self class] clientErrorStatusCodes] containsIndex:response.statusCode]) {
		HTTPErrorTitle = @"Client error";
		shouldRetry = NO;
	}

	if (error == nil && HTTPErrorTitle != nil) {
		NSDictionary *userInfo = @{
			NSLocalizedDescriptionKey : HTTPErrorTitle,
			NSLocalizedFailureReasonErrorKey: HTTPErrorMessage,
			NSURLErrorFailingURLErrorKey: self.request.URL
		};
		error = [NSError errorWithDomain:ApptentiveHTTPErrorDomain code:response.statusCode userInfo:userInfo];
	}

	if (shouldRetry) {
		[self retryTaskWithError:error];
	} else {
		[self finishWithError:error];
	}
}

- (void)retryTaskWithError:(NSError *)error {
	if ([self.delegate respondsToSelector:@selector(requestOperationWillRetry:withError:)]) {
		[self.delegate requestOperationWillRetry:self withError:error];
	}

	[self.dataSource increaseBackoffDelay];

	sleep(self.dataSource.backoffDelay);

	[self startTask];
}

- (void)completeOperation {
	[self willChangeValueForKey:@"isFinished"];
	[self willChangeValueForKey:@"isExecuting"];
	_task = nil;
	self.wasCompleted = YES;
	[self didChangeValueForKey:@"isFinished"];
	[self didChangeValueForKey:@"isExecuting"];
}

- (void)finishWithError:(NSError *)error {
	if ([self.delegate respondsToSelector:@selector(requestOperation:didFailWithError:)]) {
		[self.delegate requestOperation:self didFailWithError:error];
	}

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

@end
