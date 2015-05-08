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
#import "ATConnect_Private.h"

NSString *const ATPersonLastUpdateValuePreferenceKey = @"ATPersonLastUpdateValuePreferenceKey";

@interface ATPersonUpdater ()

@property (nonatomic, strong) NSDictionary *updatedPersonDictionary;
@property (strong, nonatomic) ATAPIRequest *request;

@end

@implementation ATPersonUpdater

+ (void)registerDefaults {
	NSDictionary *defaultPreferences = @{ATPersonLastUpdateValuePreferenceKey: @{}};
	
	[[NSUserDefaults standardUserDefaults] registerDefaults:defaultPreferences];
}

+ (BOOL)shouldUpdate {
	[ATPersonUpdater registerDefaults];
	
	ATPersonInfo *person = [ATPersonInfo currentPerson];
	
	if (person == nil) {
		person = [[ATPersonInfo alloc] init];
		person.needsUpdate = YES;
		[person saveAsCurrentPerson];
	}
	
	return (person.needsUpdate || [self changesSinceLastUpdate].count > 0);
}

+ (NSDictionary *)changesSinceLastUpdate {
	NSDictionary *lastValue = [[NSUserDefaults standardUserDefaults] dictionaryForKey:ATPersonLastUpdateValuePreferenceKey];
	NSDictionary *currentValue = [ATPersonInfo currentPerson].apiJSON;
	
	return [ATUtilities diffDictionary:currentValue againstDictionary:lastValue];
}

- (id)initWithDelegate:(NSObject<ATPersonUpdaterDelegate> *)aDelegate {
	if ((self = [super init])) {
		[ATPersonUpdater registerDefaults];
		_delegate = aDelegate;
	}
	return self;
}

- (void)dealloc {
	_delegate = nil;
	[self cancel];
}

- (void)update {
	[self cancel];
	
	self.request = [[ATWebClient sharedClient] requestForUpdatingPerson:[[self class] changesSinceLastUpdate]];
	self.updatedPersonDictionary = [ATPersonInfo currentPerson].apiJSON;
	self.request.delegate = self;
	[self.request start];
}

- (void)cancel {
	if (self.request) {
		self.request.delegate = nil;
		[self.request cancel];
		self.request = nil;
	}
}

- (float)percentageComplete {
	if (self.request) {
		return [self.request percentageComplete];
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
			[self.delegate personUpdater:self didFinish:NO];
		}
	}
}

- (void)at_APIRequestDidProgress:(ATAPIRequest *)sender {
	// pass
}

- (void)at_APIRequestDidFail:(ATAPIRequest *)sender {
	@synchronized(self) {
		ATLogInfo(@"Request failed: %@, %@", sender.errorTitle, sender.errorMessage);
		
		[self.delegate personUpdater:self didFinish:NO];
	}
}

#pragma mark - Private

- (void)processResult:(NSDictionary *)jsonPerson {
	ATPersonInfo *person = [ATPersonInfo newPersonFromJSON:jsonPerson];
	
	if (person) {
		person.needsUpdate = NO;
		[person saveAsCurrentPerson];
		
		// Save out the value we sent to the server.
		// TODO: Save the value we got back from the server?
		[[NSUserDefaults standardUserDefaults] setObject:self.updatedPersonDictionary forKey:ATPersonLastUpdateValuePreferenceKey];
		
		[self.delegate personUpdater:self didFinish:YES];
	} else {
		[self.delegate personUpdater:self didFinish:NO];
	}
	person = nil;
}

@end
