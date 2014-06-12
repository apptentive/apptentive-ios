//
//  ATPersonUpdater.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 10/2/12.
//  Copyright (c) 2012 Apptentive, Inc. All rights reserved.
//

#import "ATPersonUpdater.h"

#import "ATConversationUpdater.h"
#import "ATUtilities.h"
#import "ATWebClient+MessageCenter.h"

NSString *const ATPersonLastUpdateValuePreferenceKey = @"ATPersonLastUpdateValuePreferenceKey";

@interface ATPersonUpdater (Private)
- (void)processResult:(NSDictionary *)jsonPerson;
@end

@interface ATPersonUpdater ()
@property (nonatomic, retain) NSDictionary *sentPersonJSON;
@end

@implementation ATPersonUpdater
@synthesize delegate, sentPersonJSON;


+ (void)registerDefaults {
	NSDictionary *defaultPreferences = @{ATPersonLastUpdateValuePreferenceKey: @{}};
	
	[[NSUserDefaults standardUserDefaults] registerDefaults:defaultPreferences];
}

- (id)initWithDelegate:(NSObject<ATPersonUpdaterDelegate> *)aDelegate {
	if ((self = [super init])) {
		[ATPersonUpdater registerDefaults];
		delegate = aDelegate;
	}
	return self;
}

- (void)dealloc {
	delegate = nil;
	[self cancel];
	[sentPersonJSON release], sentPersonJSON = nil;
	[super dealloc];
}

+ (BOOL)shouldUpdate {
	[ATPersonUpdater registerDefaults];
	
	if (![ATConversationUpdater conversationExists]) {
		return NO;
	}
	
	ATPersonInfo *person = nil;
	if ([ATPersonInfo personExists]) {
		person = [ATPersonInfo currentPerson];
	} else {
		person = [[[ATPersonInfo alloc] init] autorelease];
		person.needsUpdate = YES;
		[person saveAsCurrentPerson];
	}
	
	// If person needsUpdate, then do so.
	if (!person || person.needsUpdate) {
		return YES;
	}
	
	// Otherwise, check to see if value has changed since last sent to the server.
	BOOL shouldUpdate = NO;
	
	NSObject *lastValue = [[NSUserDefaults standardUserDefaults] objectForKey:ATPersonLastUpdateValuePreferenceKey];
	if (lastValue == nil || ![lastValue isKindOfClass:[NSDictionary class]]) {
		shouldUpdate = YES;
	} else {
		NSDictionary *lastValueDictionary = (NSDictionary *)lastValue;
		NSDictionary *currentValueDictionary = [person safeApiJSON];
		if (![ATUtilities dictionary:currentValueDictionary isEqualToDictionary:lastValueDictionary]) {
			shouldUpdate = YES;
		}
	}
	
	return shouldUpdate;
}

- (void)update {
	[self cancel];
	ATPersonInfo *person = [ATPersonInfo currentPerson];
	if (person) {
		person.needsUpdate = YES;
		[person saveAsCurrentPerson];
	}
	self.sentPersonJSON = [person safeApiJSON];
	request = [[[ATWebClient sharedClient] requestForUpdatingPerson:person] retain];
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

- (float)percentageComplete {
	if (request) {
		return [request percentageComplete];
	} else {
		return 0.0f;
	}
}

#pragma mark ATATIRequestDelegate
- (void)at_APIRequestDidFinish:(ATAPIRequest *)sender result:(NSObject *)result {
	@synchronized (self) {
		if ([result isKindOfClass:[NSDictionary class]]) {
			[self processResult:(NSDictionary *)result];
		} else {
			ATLogError(@"Person result is not NSDictionary!");
			[delegate personUpdater:self didFinish:NO];
		}
	}
}

- (void)at_APIRequestDidProgress:(ATAPIRequest *)sender {
	// pass
}

- (void)at_APIRequestDidFail:(ATAPIRequest *)sender {
	@synchronized(self) {
		ATLogInfo(@"Request failed: %@, %@", sender.errorTitle, sender.errorMessage);
		
		[delegate personUpdater:self didFinish:NO];
	}
}
@end

@implementation ATPersonUpdater (Private)
- (void)processResult:(NSDictionary *)jsonPerson {
	ATPersonInfo *person = [ATPersonInfo newPersonFromJSON:jsonPerson];
	
	if (person) {
		person.needsUpdate = NO;
		[person saveAsCurrentPerson];
		
		// Save out the value we sent to the server.
		[[NSUserDefaults standardUserDefaults] setObject:self.sentPersonJSON forKey:ATPersonLastUpdateValuePreferenceKey];
		
		[delegate personUpdater:self didFinish:YES];
	} else {
		[delegate personUpdater:self didFinish:NO];
	}
	[person release], person = nil;
}
@end
