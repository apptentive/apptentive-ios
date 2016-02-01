//
//  ATConversationUpdater.m
//  ApptentiveConnect
//
//  Created by Frank Schmitt on 1/26/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import "ATConversationUpdater.h"
#import "ATConversation.h"
#import "ATConnect_Private.h"
#import "ATWebClient+MessageCenter.h"

NSString *const ATCurrentConversationPreferenceKey = @"ATCurrentConversationPreferenceKey";
NSString *const ATConversationLastUpdateValuePreferenceKey = @"ATConversationLastUpdateValuePreferenceKey";
static NSString *const ATMessagesLastRetrievedMessageIDPreferenceKey = @"ATMessagesLastRetrievedMessagIDPreferenceKey";

@interface ATConversationUpdater()

@property (readonly, nonatomic) NSString *lastUpdatePath;
@property (strong, nonatomic) NSDate *lastUpdated;

@end

@implementation ATConversationUpdater

+ (Class<ATUpdatable>)updatableClass {
	return [ATConversation class];
}

- (id<ATUpdatable>)currentVersionFromUserDefaults:(NSUserDefaults *)userDefaults {
	NSData *archiveData = [userDefaults objectForKey:ATCurrentConversationPreferenceKey];

	if (archiveData) {
		ATConversation *result = [NSKeyedUnarchiver unarchiveObjectWithData:archiveData];
		result.lastRetrievedMessageID = [userDefaults stringForKey:ATMessagesLastRetrievedMessageIDPreferenceKey];
		return result;
	} else {
		return nil;
	}
}

- (void)removeCurrentVersionFromUserDefaults:(NSUserDefaults *)userDefaults {
	[userDefaults removeObjectForKey:ATCurrentConversationPreferenceKey];
	[userDefaults removeObjectForKey:ATMessagesLastRetrievedMessageIDPreferenceKey];
}

- (id<ATUpdatable>)previousVersionFromUserDefaults:(NSUserDefaults *)userDefaults {
	NSDictionary *dictionary = [userDefaults objectForKey:ATConversationLastUpdateValuePreferenceKey];

	if (dictionary) {
		return [[[self class] updatableClass] newInstanceFromDictionary:dictionary];
	} else {
		return nil;
	}
}

- (void)removePreviousVersionFromUserDefaults:(NSUserDefaults *)userDefaults {
	[userDefaults removeObjectForKey:ATConversationLastUpdateValuePreferenceKey];
}

- (id<ATUpdatable>)emptyCurrentVersion {
	return [[ATConversation alloc] init];
}


- (void)didUpdateWithRequest:(ATAPIRequest *)request {
	_creating = NO;

	[super didUpdateWithRequest:request];
}

- (ATAPIRequest *)requestForUpdating {
	return [[ATConnect sharedConnection].webClient requestForUpdatingConversation:(ATConversation *)self.currentVersion];
}

- (ATAPIRequest *)requestForCreating {
	return [[ATConnect sharedConnection].webClient requestForCreatingConversation:(ATConversation *)self.currentVersion];
}

- (void)create {
	[self cancel];
	self.updateVersion = self.currentVersion;
	self.request = [self requestForCreating];
	self.request.delegate = self;
	_creating = YES;
	[self.request start];
}

- (BOOL)needsCreation {
	return ((ATConversation *)self.currentVersion).token == nil;
}

- (ATConversation *)currentConversation {
	return (ATConversation *)self.currentVersion;
}

@end
