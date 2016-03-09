//
//  ATEngagementManifestUpdater.m
//  ApptentiveConnect
//
//  Created by Frank Schmitt on 1/27/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import "ATEngagementManifestUpdater.h"
#import "ATEngagementManifest.h"
#import "ATExpiry.h"
#import "ATConnect_Private.h"
#import "ATWebClient+EngagementAdditions.h"
#import "ATBackend.h"

@interface ATEngagementManifestUpdater ()

@property (readonly, nonatomic) NSString *cachedInteractionsStoragePath;
@property (readonly, nonatomic) NSString *cachedTargetsStoragePath;

@property (readonly, nonatomic) ATEngagementManifest *manifest;

@end

NSString *const ATEngagementInteractionsSDKVersionKey = @"ATEngagementInteractionsSDKVersionKey";
NSString *const ATEngagementInteractionsAppBuildNumberKey = @"ATEngagementInteractionsAppBuildNumberKey";
NSString *const ATEngagementCachedInteractionsExpirationPreferenceKey = @"ATEngagementCachedInteractionsExpirationPreferenceKey";

@implementation ATEngagementManifestUpdater

+ (Class<ATUpdatable>)updatableClass {
	return [ATEngagementManifest class];
}

- (ATExpiry *)expiryFromUserDefaults:(NSUserDefaults *)userDefaults {
	NSDate *expirationDate =  [userDefaults objectForKey:ATEngagementCachedInteractionsExpirationPreferenceKey];
	NSString *appBuild = [userDefaults objectForKey:ATEngagementInteractionsAppBuildNumberKey];
	NSString *SDKVersion = [userDefaults objectForKey:ATEngagementInteractionsSDKVersionKey];

	if (expirationDate || appBuild || SDKVersion) {
		return [[ATExpiry alloc] initWithExpirationDate:expirationDate ?: [NSDate distantPast] appBuild:appBuild SDKVersion:SDKVersion];
	} else {
		return nil;
	}
}

- (void)removeExpiryFromUserDefaults:(NSUserDefaults *)userDefaults {
	[userDefaults removeObjectForKey:ATEngagementCachedInteractionsExpirationPreferenceKey];
	[userDefaults removeObjectForKey:ATEngagementInteractionsSDKVersionKey];
	[userDefaults removeObjectForKey:ATEngagementInteractionsAppBuildNumberKey];
}

- (NSString *)cachedTargetsStoragePath {
	return [[ATConnect sharedConnection].backend.storagePath stringByAppendingPathComponent:@"cachedtargets.objects"];
}

- (NSString *)cachedInteractionsStoragePath {
	return [[ATConnect sharedConnection].backend.storagePath stringByAppendingPathComponent:@"cachedinteractionsV2.objects"];
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

- (id<ATUpdatable>)emptyCurrentVersion {
	return [[ATEngagementManifest alloc] init];
}

- (ATAPIRequest *)requestForUpdating {
	return [[ATConnect sharedConnection].webClient requestForGettingEngagementManifest];
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
