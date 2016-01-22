//
//  ATAppConfigurationUpdater.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 3/18/12.
//  Copyright (c) 2012 Apptentive, Inc. All rights reserved.
//

#import "ATAppConfigurationUpdater.h"
#import "ATAppConfiguration.h"
#import "ATUtilities.h"
#import "ATWebClient.h"
#import "ATConnect_Private.h"
#import "ATBackend.h"

NSString *const ATConfigurationPreferencesChangedNotification = @"ATConfigurationPreferencesChangedNotification";

@interface ATAppConfigurationUpdater ()
- (void)processResult:(NSDictionary *)jsonRatingConfiguration maxAge:(NSTimeInterval)expiresMaxAge;
@end


@implementation ATAppConfigurationUpdater {
	ATAPIRequest *request;
}

+ (BOOL)shouldCheckForUpdate {
	return ![ATConnect sharedConnection].backend.appConfiguration.valid;
}

- (id)initWithDelegate:(NSObject<ATAppConfigurationUpdaterDelegate> *)aDelegate {
	if ((self = [super init])) {
		_delegate = aDelegate;
	}
	return self;
}

- (void)dealloc {
	self.delegate = nil;
	[self cancel];
}

- (void)update {
	[self cancel];
	request = [[ATConnect sharedConnection].webClient requestForGettingAppConfiguration];
	request.delegate = self;
	[request start];
}

- (void)cancel {
	if (request) {
		request.delegate = nil;
		[request cancel];
		request = nil;
	}
}

- (float)percentageComplete {
	if (request) {
		return [request percentageComplete];
	} else {
		return 0.0f;
	}
}

#pragma mark ATATIRequestDelegate
- (void)at_APIRequestDidFinish:(ATAPIRequest *)sender result:(NSObject *)result {
	@synchronized(self) {
		if ([result isKindOfClass:[NSDictionary class]]) {
			[self processResult:(NSDictionary *)result maxAge:[sender expiresMaxAge]];
			[self.delegate configurationUpdaterDidFinish:YES];
		} else {
			ATLogError(@"App configuration result is not NSDictionary!");
			[self.delegate configurationUpdaterDidFinish:NO];
		}
	}
}

- (void)at_APIRequestDidProgress:(ATAPIRequest *)sender {
	// pass
}

- (void)at_APIRequestDidFail:(ATAPIRequest *)sender {
	@synchronized(self) {
		ATLogInfo(@"Request failed: %@, %@", sender.errorTitle, sender.errorMessage);

		[self.delegate configurationUpdaterDidFinish:NO];
	}
}

#pragma mark - Private methods

- (void)processResult:(NSDictionary *)jsonConfiguration maxAge:(NSTimeInterval)expiresMaxAge {
	ATAppConfiguration *previousAppConfiguration = [ATConnect sharedConnection].backend.appConfiguration;
	ATAppConfiguration *currentAppConfiguration = [[ATAppConfiguration alloc] initWithJSONDictionary:jsonConfiguration validForInterval:expiresMaxAge];

	[ATConnect sharedConnection].backend.appConfiguration = currentAppConfiguration;

	if (![currentAppConfiguration isEqual:previousAppConfiguration]) {

		[[NSNotificationCenter defaultCenter] postNotificationName:ATConfigurationPreferencesChangedNotification object:nil];
	}
}

@end
