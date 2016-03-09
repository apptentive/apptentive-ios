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
	NSData *personInfoData = [userDefaults objectForKey:ATCurrentPersonPreferenceKey];

	if (personInfoData) {
		return [NSKeyedUnarchiver unarchiveObjectWithData:personInfoData];
	} else {
		return nil;
	}
}

- (void)removeCurrentVersionFromUserDefaults:(NSUserDefaults *)userDefaults {
	[userDefaults removeObjectForKey:ATCurrentPersonPreferenceKey];
}

- (id<ATUpdatable>)previousVersionFromUserDefaults:(NSUserDefaults *)userDefaults {
	NSData *dictionaryData = [userDefaults objectForKey:ATPersonLastUpdateValuePreferenceKey];

	if (dictionaryData) {
		NSDictionary *dictionary = [NSKeyedUnarchiver unarchiveObjectWithData:dictionaryData];
		return [[[self class] updatableClass] newInstanceFromDictionary:dictionary];
	} else {
		return nil;
	}
}

- (void)removePreviousVersionFromUserDefaults:(NSUserDefaults *)userDefaults {
	[userDefaults removeObjectForKey:ATPersonLastUpdateValuePreferenceKey];
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
