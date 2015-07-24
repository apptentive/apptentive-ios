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

@interface ATPersonUpdater ()

@property (nonatomic, strong) NSDictionary *sentPersonJSON;
@property (strong, nonatomic) ATAPIRequest *request;

@end

@implementation ATPersonUpdater

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

+ (BOOL)shouldUpdate {
	[ATPersonUpdater registerDefaults];
	
	return [[ATPersonInfo currentPerson] apiJSON].count > 0;
}

+ (NSDictionary *)lastSavedVersion {
	return [[NSUserDefaults standardUserDefaults] dictionaryForKey:ATPersonLastUpdateValuePreferenceKey];
}

- (void)update {
	[self cancel];
	ATPersonInfo *person = [ATPersonInfo currentPerson];
	self.sentPersonJSON = person.dictionaryRepresentation;
	self.request = [[ATWebClient sharedClient] requestForUpdatingPerson:person];
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

+ (void)registerDefaults {
	NSDictionary *defaultPreferences = @{ATPersonLastUpdateValuePreferenceKey: @{}};
	
	[[NSUserDefaults standardUserDefaults] registerDefaults:defaultPreferences];
}

- (void)processResult:(NSDictionary *)jsonPerson {
	ATPersonInfo *person = [ATPersonInfo newPersonFromJSON:jsonPerson];
	
	if (person) {
		// Save out the value we sent to the server.
		[[NSUserDefaults standardUserDefaults] setObject:self.sentPersonJSON forKey:ATPersonLastUpdateValuePreferenceKey];
		
		[self.delegate personUpdater:self didFinish:YES];
	} else {
		[self.delegate personUpdater:self didFinish:NO];
	}
	person = nil;
}
@end
