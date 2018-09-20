//
//  ApptentiveClient.m
//  Apptentive
//
//  Created by Frank Schmitt on 4/24/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveClient.h"
#import "ApptentiveConfigurationRequest.h"
#import "ApptentiveConversationRequest.h"
#import "ApptentiveMessageGetRequest.h"

#import "ApptentiveSerialRequest.h"
#import "ApptentiveGCDDispatchQueue.h"
#import "ApptentiveRetryPolicy.h"

#define APPTENTIVE_MIN_BACKOFF_DELAY 5.0
#define APPTENTIVE_BACKOFF_MULTIPLIER 2.0
#define APPTENTIVE_BACKOFF_CAP 10.0 * 60.0

NS_ASSUME_NONNULL_BEGIN

@interface ApptentiveClient ()

@property (strong, nonatomic) ApptentiveRetryPolicy *retryPolicy;

@end


@implementation ApptentiveClient

@synthesize URLSession = _URLSession;

+ (NSIndexSet *)okStatusCodes {
	static NSIndexSet *_okStatusCodes;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		_okStatusCodes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(200, 100)]; // 2xx status codes
	});

	return _okStatusCodes;
}

+ (NSIndexSet *)clientErrorStatusCodes {
	static NSIndexSet *_clientErrorStatusCodes;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		_clientErrorStatusCodes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(400, 100)]; // 4xx status codes

	});

	return _clientErrorStatusCodes;
}

+ (NSIndexSet *)serverErrorStatusCodes {
	static NSIndexSet *_serverErrorStatusCodes;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		_serverErrorStatusCodes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(500, 100)]; // 5xx status codes

	});

	return _serverErrorStatusCodes;
}

- (instancetype)initWithBaseURL:(NSURL *)baseURL apptentiveKey:(nonnull NSString *)apptentiveKey apptentiveSignature:(nonnull NSString *)apptentiveSignature delegateQueue:(ApptentiveDispatchQueue *)delegateQueue {
	self = [super init];

	if (self) {
		_baseURL = baseURL;
		_apptentiveKey = apptentiveKey;
		_apptentiveSignature = apptentiveSignature;
		_networkQueue = [NSOperationQueue new];

		_retryPolicy = [[ApptentiveRetryPolicy alloc] initWithInitialBackoff:APPTENTIVE_MIN_BACKOFF_DELAY base:APPTENTIVE_BACKOFF_MULTIPLIER];
		_retryPolicy.shouldAddJitter = YES;
		_retryPolicy.cap = APPTENTIVE_BACKOFF_CAP;
		_retryPolicy.retryStatusCodes = [[self class] serverErrorStatusCodes];

		NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
		configuration.HTTPAdditionalHeaders = @{
			@"Accept": @"application/json",
			@"Accept-Encoding": @"gzip",
			@"Accept-Charset": @"utf-8",
			@"User-Agent": [NSString stringWithFormat:@"ApptentiveConnect/%@ (iOS)", kApptentiveVersionString],
		};

		configuration.requestCachePolicy = NSURLRequestReloadIgnoringCacheData;
		configuration.URLCache = nil;

		_URLSession = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:((ApptentiveGCDDispatchQueue *) delegateQueue).queue];
	}

	return self;
}

- (void)setPaused:(BOOL)paused {
	_paused = paused;

	ApptentiveLogInfo(ApptentiveLogTagNetwork, @"%@ %@", paused ? @"Pausing" : @"Resuming", NSStringFromClass([self class]));
	self.networkQueue.suspended = self.paused;
}

#pragma mark - Creating request operations

- (ApptentiveRequestOperation *)requestOperationWithRequest:(id<ApptentiveRequest>)request token:(nullable NSString *)token delegate:(ApptentiveRequestOperationCallback *)delegate {
	NSMutableURLRequest *URLRequest = [self URLRequestWithRequest:request];
	if (token && !request.encrypted) {
		[URLRequest addValue:[@"Bearer " stringByAppendingString:token] forHTTPHeaderField:@"Authorization"];
	}

	ApptentiveRequestOperation *operation = [[ApptentiveRequestOperation alloc] initWithURLRequest:URLRequest delegate:delegate dataSource:self];
	operation.request = request;
	return operation;
}

- (ApptentiveRequestOperation *)requestOperationWithRequest:(id<ApptentiveRequest>)request legacyToken:(NSString *_Nullable)token delegate:(ApptentiveRequestOperationCallback *)delegate {
	NSMutableURLRequest *URLRequest = [self URLRequestWithRequest:request];
	if (token) {
		[URLRequest addValue:[@"OAuth " stringByAppendingString:token] forHTTPHeaderField:@"Authorization"];
	}

	ApptentiveRequestOperation *operation = [[ApptentiveRequestOperation alloc] initWithURLRequest:URLRequest delegate:delegate dataSource:self];
	operation.request = request;
	return operation;
}

- (NSMutableURLRequest *)URLRequestWithRequest:(id<ApptentiveRequest>)request {
	NSURL *URL = [NSURL URLWithString:request.path relativeToURL:self.baseURL];

	NSMutableURLRequest *URLRequest = [NSMutableURLRequest requestWithURL:URL];
	URLRequest.HTTPBody = request.payload;
	URLRequest.HTTPMethod = request.method;
	[URLRequest addValue:request.contentType forHTTPHeaderField:@"Content-Type"];
	[URLRequest addValue:request.apiVersion forHTTPHeaderField:@"X-API-Version"];
	[URLRequest addValue:_apptentiveKey forHTTPHeaderField:@"APPTENTIVE-KEY"];
	[URLRequest addValue:_apptentiveSignature forHTTPHeaderField:@"APPTENTIVE-SIGNATURE"];
	if (request.encrypted) {
		[URLRequest addValue:@"true" forHTTPHeaderField:@"APPTENTIVE-ENCRYPTED"];
	}
	return URLRequest;
}

@end

NS_ASSUME_NONNULL_END
