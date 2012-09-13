//
//  ATURLConnection.m
//
//  Created by Andrew Wooster on 12/14/08.
//  Copyright 2008 Apptentive, Inc.. All rights reserved.
//

#import "ATURLConnection.h"
#import "ATURLConnection_Private.h"
#if TARGET_OS_IPHONE_BOGUS
#import "PSNetworkActivityIndicator.h"
#endif

@interface ATURLConnection ()
- (void)cacheDataIfNeeded;
@end


@implementation ATURLConnection
@synthesize targetURL;
@synthesize delegate;
@synthesize connection;
@synthesize executing;
@synthesize finished;
@synthesize cancelled;
@synthesize failed;
@synthesize timeoutInterval;
@synthesize credential;
@synthesize statusCode;
@synthesize failedAuthentication;
@synthesize connectionError;
@synthesize percentComplete;

- (id)initWithURL:(NSURL *)url {
	return [self initWithURL:url delegate:nil];
}

- (id)initWithURL:(NSURL *)url delegate:(id)aDelegate {
	if ((self = [super init])) {
		targetURL = [url copy];
		delegate = aDelegate;
		data = [[NSMutableData alloc] init];
		finished = NO;
		executing = NO;
		failed = NO;
		failedAuthentication = NO;
		timeoutInterval = 10.0;
		
		headers = [[NSMutableDictionary alloc] init];
		HTTPMethod = nil;
		
		statusCode = 0;
		percentComplete = 0.0f;
		return self;
	}
	return nil;
}

- (BOOL)isExecuting {
	return self.executing;
}

- (BOOL)isFinished {
	return self.finished;
}

- (BOOL)isCancelled {
	return self.cancelled;
}

- (void)setValue:(NSString *)value forHTTPHeaderField:(NSString *)field {
	[headers setValue:value forKey:field];
}

- (void)setHTTPMethod:(NSString *)method {
	if (HTTPMethod != method) {
		[HTTPMethod release];
		HTTPMethod = [method retain];
	}
}

- (void)setHTTPBody:(NSData *)body {
	if (HTTPBody != body) {
		[HTTPBody release];
		HTTPBody = [body retain];
	}
}

- (void)start {
	@synchronized (self) {
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		
		do { // once
			if ([self isCancelled]) {
				self.finished = YES;
				break;
			}
			if ([self isFinished]) {
				break;
			}
			NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:self.targetURL cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:timeoutInterval];
			for (NSString *key in headers) {
				[request setValue:[headers objectForKey:key] forHTTPHeaderField:key];
			}
			if (HTTPMethod) {
				[request setHTTPMethod:HTTPMethod];
			}
			if (HTTPBody) {
				[request setHTTPBody:HTTPBody];
			}
			self.connection = [[[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:NO] autorelease];
			[self.connection scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
			[self.connection start];
			self.executing = YES;
			[request release];
#if TARGET_OS_IPHONE_BOGUS
			[[PSNetworkActivityIndicator sharedIndicator] increment];
#endif
		} while (NO);
		[pool drain];
	}
}

- (NSData *)responseData {
	if (data) {
		return data;
	}
	return nil;
}

#pragma mark Delegate Methods
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSHTTPURLResponse *)response {
	@synchronized (self) {
		[data setLength:0];
		if (response ) {
			if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
				statusCode = response.statusCode;
			} else {
				statusCode = 200;
			}
		}
	}
}
- (void)connection:(NSURLConnection *)aConnection didFailWithError:(NSError *)error {
	@synchronized (self) {
		self.failed = YES;
		self.finished = YES;
		self.executing = NO;
		if (error) {
			self.connectionError = error;
		}
#if TARGET_OS_IPHONE_BOGUS
		[[PSNetworkActivityIndicator sharedIndicator] decrement];
#endif
		if (delegate && [delegate respondsToSelector:@selector(connectionFailed:)]){
			[delegate performSelectorOnMainThread:@selector(connectionFailed:) withObject:self waitUntilDone:YES];
		} else {
			NSLog(@"Orphaned connection. No delegate or nonresponsive delegate.");
		}
	}
}

- (void)connection:(NSURLConnection *)aConnection didReceiveData:(NSData *)someData {
	@synchronized (self) {
		[data appendData:someData];
	}
}

- (void)connectionDidFinishLoading:(NSURLConnection *)aConnection {
	@synchronized (self) {
		if (data && !failed) {
			if (delegate != nil && ![self isCancelled]) {
				self.percentComplete = 1.0f;
				[self cacheDataIfNeeded];
				if (delegate && [delegate respondsToSelector:@selector(connectionFinishedSuccessfully:)]){
					[delegate performSelectorOnMainThread:@selector(connectionFinishedSuccessfully:) withObject:self waitUntilDone:YES];
				} else {
					NSLog(@"Orphaned connection. No delegate or nonresponsive delegate.");
				}
			}
			[data release];
			data = nil;
		} else if (delegate && ![self isCancelled]) {
			if (delegate && [delegate respondsToSelector:@selector(connectionFailed:)]){
				[delegate performSelectorOnMainThread:@selector(connectionFailed:) withObject:self waitUntilDone:YES];
			} else {
				NSLog(@"Orphaned connection. No delegate or nonresponsive delegate.");
			}
		}
#if TARGET_OS_IPHONE_BOGUS
		[[PSNetworkActivityIndicator sharedIndicator] decrement];
#endif
		self.executing = NO;
		self.finished = YES;
	}
}

-(void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
	@synchronized (self) {
		if (credential && [challenge previousFailureCount] == 0) {
			[[challenge sender] useCredential:credential forAuthenticationChallenge:challenge];
		} else {
			failedAuthentication = YES;
			[[challenge sender] cancelAuthenticationChallenge:challenge];
		}
	}
}

- (void)connection:(NSURLConnection *)connection didCancelAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
	@synchronized (self) {
		self.failed = YES;
		self.finished = YES;
		self.executing = NO;
		failedAuthentication = YES;
#if TARGET_OS_IPHONE_BOGUS
		[[PSNetworkActivityIndicator sharedIndicator] decrement];
#endif
		if (delegate && [delegate respondsToSelector:@selector(connectionFailed:)]){
			[delegate performSelectorOnMainThread:@selector(connectionFailed:) withObject:self waitUntilDone:YES];
		} else {
			NSLog(@"Orphaned connection. No delegate or nonresponsive delegate.");
		}
	}
}

- (void)connection:(NSURLConnection *)connection didSendBodyData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite {
	if (delegate && [delegate respondsToSelector:@selector(connectionDidProgress:)]) {
		self.percentComplete = ((float)totalBytesWritten)/((float) totalBytesExpectedToWrite);
		[delegate performSelectorOnMainThread:@selector(connectionDidProgress:) withObject:self waitUntilDone:YES];
	} else {
		NSLog(@"Orphaned connection. No delegate or nonresponsive delegate.");
	}
}

- (void)setExecuting:(BOOL)isExecuting {
	[self willChangeValueForKey:@"isExecuting"];
	executing = isExecuting;
	[self didChangeValueForKey:@"isExecuting"];
}

- (void)setFinished:(BOOL)isFinished {
	[self willChangeValueForKey:@"isFinished"];
	finished = isFinished;
	[self didChangeValueForKey:@"isFinished"];
}

- (void)cacheDataIfNeeded {
	
}

- (void)dealloc {
	@synchronized (self) {
		delegate = nil;
		[targetURL release];
		if (connection) {
			[connection release];
		}
		[data release];
		data = nil;
		
		if (credential) {
			[credential release];
		}
		if (connectionError) {
			[connectionError release];
		}
		
		[headers release];
		[HTTPMethod release];
		[HTTPBody release];
	}
	[super dealloc];
}

- (NSString *)requestAsString {
	NSMutableString *result = [NSMutableString string];
	[result appendFormat:@"%@ %@\n", HTTPMethod ? HTTPMethod : @"GET", [targetURL absoluteURL]];
	for (NSString *key in headers) {
		NSString *value = [headers valueForKey:key];
		[result appendFormat:@"%@: %@\n", key, value];
	}
	[result appendString:@"\n\n"];
	if (HTTPBody) {
		NSString *a = [[[NSString alloc] initWithData:HTTPBody encoding:NSUTF8StringEncoding] autorelease];
		if (a) {
			[result appendString:a];
		} else {
			[result appendFormat:@"<Data of length:%ld>", (long)[HTTPBody length]];
		}
	}
	return result;
}
@end

@implementation ATURLConnection (Private)
- (void)cancel {
	@synchronized (self) {
		if (self.finished) {
			return;
		}
		delegate = nil;
		if (connection) {
			[connection cancel];
#if TARGET_OS_IPHONE_BOGUS
			[[PSNetworkActivityIndicator sharedIndicator] decrement];
#endif
		}
		self.executing = NO;
		cancelled = YES;
	}
}
@end
