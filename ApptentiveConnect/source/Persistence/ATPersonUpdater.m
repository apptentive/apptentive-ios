//
//  ATPersonUpdater.m
//  ApptentiveConnect
//
//  Created by Frank Schmitt on 1/26/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import "ATPersonUpdater.h"
#import "ATPersonInfo.h"
#import "ATConnect_Private.h"
#import "ATWebClient+MessageCenter.h"

NSString *const ATPersonLastUpdateValuePreferenceKey = @"ATPersonLastUpdateValuePreferenceKey";
NSString *const ATCurrentPersonPreferenceKey = @"ATCurrentPersonPreferenceKey";

@implementation ATPersonUpdater

+ (Class <ATUpdatable>)updatableClass {
	return [ATPersonInfo class];
}

- (id<ATUpdatable>)currentVersionFromUserDefaults:(NSUserDefaults *)userDefaults {
	NSDictionary *dictionary = [userDefaults objectForKey:ATCurrentPersonPreferenceKey];

	return [[[self class] updatableClass] newInstanceFromDictionary:dictionary];
}

- (id<ATUpdatable>)previousVersionFromUserDefaults:(NSUserDefaults *)userDefaults {
	NSDictionary *dictionary = [userDefaults objectForKey:ATPersonLastUpdateValuePreferenceKey];

	return [[[self class] updatableClass] newInstanceFromDictionary:dictionary];
}

- (id<ATUpdatable>)emptyCurrentVersion {
	return [[ATPersonInfo alloc] init];
}

- (ATAPIRequest *)requestForUpdating {
	return [[ATConnect sharedConnection].webClient requestForUpdatingPerson:(ATPersonInfo *)self.currentVersion fromPreviousPerson:(ATPersonInfo *)self.previousVersion];
}

- (ATPersonInfo *)currentPerson {
	return (ATPersonInfo *)self.currentVersion;
}

@end
