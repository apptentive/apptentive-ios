//
//  ATActivityFeedUpdater.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 2/4/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import "ATActivityFeedUpdater.h"

#import "ATBackend.h"
#import "ATWebClient+MessageCenter.h"

NSString *const ATCurrentActivityFeedPreferenceKey = @"ATCurrentActivityFeedPreferenceKey";

@interface ATActivityFeedUpdater (Private)
- (void)processResult:(NSDictionary *)jsonActivityFeed;
@end

@implementation ATActivityFeedUpdater
@synthesize delegate;

- (id)initWithDelegate:(NSObject<ATActivityFeedUpdaterDelegate> *)aDelegate {
	if ((self = [super init])) {
		delegate = aDelegate;
	}
	return self;
}

- (void)dealloc {
	delegate = nil;
	[self cancel];
	[super dealloc];
}

- (void)createActivityFeed {
	[self cancel];
	ATActivityFeed *activityFeed = [[ATActivityFeed alloc] init];
	activityFeed.deviceID = [[ATBackend sharedBackend] deviceUUID];
	request = [[[ATWebClient sharedClient] requestForCreatingActivityFeed:activityFeed] retain];
	request.delegate = self;
	[request start];
	[activityFeed release], activityFeed = nil;
}

- (void)cancel {
	if (request) {
		request.delegate = nil;
		[request cancel];
		[request release], request = nil;
	}
}

- (float)percentageComplete {
	if (request) {
		return [request percentageComplete];
	} else {
		return 0.0f;
	}
}

+ (BOOL)activityFeedExists {
	ATActivityFeed *currentFeed = [ATActivityFeedUpdater currentActivityFeed];
	if (currentFeed == nil) {
		return NO;
	} else {
		return YES;
	}
}

+ (ATActivityFeed *)currentActivityFeed {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSData *feedData = [defaults dataForKey:ATCurrentActivityFeedPreferenceKey];
	if (!feedData) {
		return nil;
	}
	ATActivityFeed *feed = [NSKeyedUnarchiver unarchiveObjectWithData:feedData];
	return feed;
}

#pragma mark ATATIRequestDelegate
- (void)at_APIRequestDidFinish:(ATAPIRequest *)sender result:(NSObject *)result {
	@synchronized (self) {
		if ([result isKindOfClass:[NSDictionary class]]) {
			[self processResult:(NSDictionary *)result];
		} else {
			NSLog(@"Activity feed result is not NSDictionary!");
			[delegate activityFeed:self createdFeed:NO];
		}
	}
}

- (void)at_APIRequestDidProgress:(ATAPIRequest *)sender {
	// pass
}

- (void)at_APIRequestDidFail:(ATAPIRequest *)sender {
	@synchronized(self) {
		NSLog(@"Request failed: %@, %@", sender.errorTitle, sender.errorMessage);
		
		[delegate activityFeed:self createdFeed:NO];
	}
}

@end


@implementation ATActivityFeedUpdater (Private)
- (void)processResult:(NSDictionary *)jsonActivityFeed {
	ATActivityFeed *feed = (ATActivityFeed *)[ATActivityFeed newInstanceWithJSON:jsonActivityFeed];
	if (feed) {
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		NSData *feedData = [NSKeyedArchiver archivedDataWithRootObject:feed];
		[defaults setObject:feedData forKey:ATCurrentActivityFeedPreferenceKey];
		[defaults synchronize];
		[delegate activityFeed:self createdFeed:YES];
	} else {
		[delegate activityFeed:self createdFeed:NO];
	}
	[feed release], feed = nil;
}
@end
