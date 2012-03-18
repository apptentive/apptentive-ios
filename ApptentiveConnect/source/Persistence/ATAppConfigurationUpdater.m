//
//  ATAppConfigurationUpdater.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 3/18/12.
//  Copyright (c) 2012 Apptentive, Inc. All rights reserved.
//

#import "ATAppConfigurationUpdater.h"
#import "ATContactStorage.h"
#import "ATWebClient.h"
#import "JSONKit.h"

NSString * const ATAppConfigurationUpdaterFinished = @"ATAppConfigurationUpdaterFinished";

@interface ATAppConfigurationUpdater (Private)
- (void)processResult:(NSDictionary *)jsonRatingConfiguration;
@end

@implementation ATAppConfigurationUpdater
#warning Implement
+ (BOOL)shouldCheckForUpdate {
	return YES;
}
- (void)dealloc {
	[self cancel];
	[super dealloc];
}

- (void)update {
	[self cancel];
	request = [[[ATWebClient sharedClient] requestForGettingAppConfiguration] retain];
	request.delegate = self;
	[request start];
}

- (void)cancel {
	if (request) {
		request.delegate = nil;
		[request cancel];
		[request release], request = nil;
	}
}

#pragma mark ATATIRequestDelegate
- (void)at_APIRequestDidFinish:(ATAPIRequest *)sender result:(NSObject *)result {
	@synchronized (self) {
		if ([result isKindOfClass:[NSDictionary class]]) {
			[self processResult:(NSDictionary *)result];
		} else {
			NSLog(@"App configuration result is not NSDictionary!");
		}
	}
}

- (void)at_APIRequestDidProgress:(ATAPIRequest *)sender {
	// pass
}

- (void)at_APIRequestDidFail:(ATAPIRequest *)sender {
	@synchronized(self) {
		NSLog(@"Request failed: %@, %@", sender.errorTitle, sender.errorMessage);
	}
}
@end

@implementation ATAppConfigurationUpdater (Private)
- (void)processResult:(NSDictionary *)jsonRatingConfiguration {
	NSLog(@"result: %@", jsonRatingConfiguration);
}
@end

