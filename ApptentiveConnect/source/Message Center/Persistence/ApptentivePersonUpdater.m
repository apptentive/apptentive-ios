//
//  ApptentivePersonUpdater.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 10/2/12.
//  Copyright (c) 2012 Apptentive, Inc. All rights reserved.
//

#import "ApptentivePersonUpdater.h"

#import "ApptentiveUtilities.h"
#import "Apptentive_Private.h"
#import "ApptentiveQueuedRequest.h"
#import "ApptentiveData.h"
#import "ApptentiveBackend.h"

NSString *const ATPersonLastUpdateValuePreferenceKey = @"ATPersonLastUpdateValuePreferenceKey";


@implementation ApptentivePersonUpdater

+ (BOOL)shouldUpdate {
	[ApptentivePersonUpdater registerDefaults];

	return [[ApptentivePersonInfo currentPerson] apiJSON].count > 0;
}

+ (NSDictionary *)lastSavedVersion {
	NSData *data = [[NSUserDefaults standardUserDefaults] dataForKey:ATPersonLastUpdateValuePreferenceKey];

	if (data) {
		NSDictionary *dictionary = [NSKeyedUnarchiver unarchiveObjectWithData:data];
		if ([dictionary isKindOfClass:[NSDictionary class]]) {
			return dictionary;
		}
	}

	return nil;
}

+ (void)resetPersonInfo {
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:ATPersonLastUpdateValuePreferenceKey];
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:ATCurrentPersonPreferenceKey];
}

- (void)update {
	ApptentivePersonInfo *person = [ApptentivePersonInfo currentPerson];

	[ApptentiveQueuedRequest enqueueRequestWithPath:@"people" payload:person.apiJSON attachments:nil identifier:nil inContext:Apptentive.shared.backend.managedObjectContext];

	[Apptentive.shared.backend processQueuedRecords];

	NSData *data = [NSKeyedArchiver archivedDataWithRootObject:person.dictionaryRepresentation];
	[[NSUserDefaults standardUserDefaults] setObject:data forKey:ATPersonLastUpdateValuePreferenceKey];

}

#pragma mark - Private

+ (void)registerDefaults {
	NSDictionary *defaultPreferences = @{ ATPersonLastUpdateValuePreferenceKey: @{} };

	[[NSUserDefaults standardUserDefaults] registerDefaults:defaultPreferences];
}

@end
