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


@implementation ApptentiveRequestOperation

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
	return self.wasCompleted;
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
		} else if (data) {
			if (((NSHTTPURLResponse *)response).statusCode == 204) {
				[self processResponse:(NSHTTPURLResponse *)response withObject:nil];
			} else {
				NSObject *responseObject = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&error];

				if (responseObject != nil) {
					[self processResponse:(NSHTTPURLResponse *)response withObject:responseObject];
				} else {
					[self processFailedResponse:(NSHTTPURLResponse *)response withError:error];
				}
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
	[self willChangeValueForKey:@"isCancelled"];
	[self.task cancel];
	self.wasCancelled = YES;
	[self didChangeValueForKey:@"isCancelled"];
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

- (void)processFailedResponse:(NSHTTPURLResponse *)response withError:(NSError *)error {
	NSIndexSet *okStatusCodes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(100, 300)];			// 1xx, 2xx, and 3xx status codes
	NSIndexSet *clientErrorStatusCodes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(400, 100)]; // 4xx status codes
	NSIndexSet *serverErrorStatusCodes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(500, 100)]; // 5xx status codes

	// TODO: Consider localizing error titles
	if (response == nil) {
		[self retryTaskWithError:error];
	} else if ([okStatusCodes containsIndex:response.statusCode]) {
		[self retryTaskWithError:error];
	} else if ([clientErrorStatusCodes containsIndex:response.statusCode]) {
		[self finishWithError:error];
	} else if ([serverErrorStatusCodes containsIndex:response.statusCode]) {
		[self retryTaskWithError:error];
	} else {
		[self retryTaskWithError:error];
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
