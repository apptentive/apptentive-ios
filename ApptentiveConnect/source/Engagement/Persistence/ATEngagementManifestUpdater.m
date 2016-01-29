//
//  ATEngagementManifestUpdater.m
//  ApptentiveConnect
//
//  Created by Frank Schmitt on 1/27/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import "ATEngagementManifestUpdater.h"
#import "ATEngagementManifest.h"

@interface ATEngagementManifestUpdater ()

@property (readonly, nonatomic) NSString *cachedInteractionsStoragePath;
@property (readonly, nonatomic) NSString *cachedTargetsStoragePath;

@property (readonly, nonatomic) ATEngagementManifest *manifest;

@end

NSString *const ATEngagementCachedInteractionsExpirationPreferenceKey = @"ATEngagementCachedInteractionsExpirationPreferenceKey";

@implementation ATEngagementManifestUpdater

+ (Class<ATUpdatable>)updatableClass {
	return [ATEngagementManifest class];
}

- (NSDate *)expiryFromUserDefaults:(NSUserDefaults *)userDefaults {
	return [userDefaults objectForKey:ATEngagementCachedInteractionsExpirationPreferenceKey];
}

- (void)removeExpiryFromUserDefaults:(NSUserDefaults *)userDefaults {
	[userDefaults removeObjectForKey:ATEngagementCachedInteractionsExpirationPreferenceKey];
}

- (NSString *)cachedTargetsStoragePath {
	return [self.storagePath stringByAppendingPathComponent:@"cachedtargets.objects"];
}

- (NSString *)cachedInteractionsStoragePath {
	return [self.storagePath stringByAppendingPathComponent:@"cachedinteractionsV2.objects"];
}

- (id<ATUpdatable>)currentVersionFromUserDefaults:(NSUserDefaults *)userDefaults {
	NSDictionary *archivedTargets;
	NSDictionary *archivedInteractions;

	NSFileManager *fm = [NSFileManager defaultManager];
	if ([fm fileExistsAtPath:self.cachedTargetsStoragePath]) {
		@try {
			archivedTargets = [NSKeyedUnarchiver unarchiveObjectWithFile:self.cachedTargetsStoragePath];
		} @catch (NSException *exception) {
			ATLogError(@"Unable to unarchive engagement targets: %@", exception);
		}
	}

	if ([fm fileExistsAtPath:self.cachedInteractionsStoragePath]) {
		@try {
			archivedInteractions = [NSKeyedUnarchiver unarchiveObjectWithFile:self.cachedInteractionsStoragePath];
		} @catch (NSException *exception) {
			ATLogError(@"Unable to unarchive engagement interactions: %@", exception);
		}
	}

	if (archivedTargets && archivedInteractions) {
		return [[ATEngagementManifest alloc] initWithTargets:archivedTargets interactions:archivedInteractions];
	} else {
		return nil;
	}
}

- (void)removeCurrentVersionFromUserDefaults:(NSUserDefaults *)userDefaults {
	[[NSFileManager defaultManager] removeItemAtPath:self.cachedInteractionsStoragePath error:NULL];
	[[NSFileManager defaultManager] removeItemAtPath:self.cachedTargetsStoragePath error:NULL];
}

- (ATEngagementManifest *)manifest {
	return (ATEngagementManifest *)self.currentVersion;
}

- (NSDictionary *)targets {
	return self.manifest.targets;
}

- (NSDictionary *)interactions {
	return self.manifest.interactions;
}

@end
