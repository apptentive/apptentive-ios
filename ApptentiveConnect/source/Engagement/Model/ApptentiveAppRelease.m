//
//  ApptentiveAppRelease.m
//  ApptentiveConnect
//
//  Created by Frank Schmitt on 11/15/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveAppRelease.h"
#import "ApptentiveVersion.h"

static NSString * const TypeKey = @"type";
static NSString * const VersionKey = @"version";
static NSString * const BuildKey = @"build";
static NSString * const HasAppStoreReceiptKey = @"hasAppStoreReceipt";
static NSString * const DebugBuildKey = @"debugBuild";
static NSString * const OverridingStylesKey = @"overridingStyles";
static NSString * const UpdateVersionKey = @"updateVersion";
static NSString * const UpdateBuildKey = @"updateBuild";
static NSString * const TimeAtInstallTotalKey = @"timeAtInstallTotal";
static NSString * const TimeAtInstallVersionKey = @"timeAtInstallVersion";
static NSString * const TimeAtInstallBuildKey = @"timeAtInstallBuild";

@implementation ApptentiveAppRelease

- (instancetype)init {
	self = [super init];

	if (self) {
		_updateVersion = NO;
		_updateBuild = NO;

		_timeAtInstallTotal = [NSDate date]; // TODO: Inject as dependency?
		_timeAtInstallVersion = [NSDate date]; // TODO: Inject as dependency?
		_timeAtInstallBuild = [NSDate date]; // TODO: Inject as dependency?
	}

	return self;
}

- (instancetype)initWithCurrentAppRelease {
	self = [super init];

	if (self) {
		_type = @"ios";
		_version = [[ApptentiveVersion alloc] initWithString:[NSBundle mainBundle].infoDictionary[@"CFBundleShortVersionString"]];
		_build = [[ApptentiveVersion alloc] initWithString:[NSBundle mainBundle].infoDictionary[(NSString *)kCFBundleVersionKey]];
		_hasAppStoreReceipt = [NSData dataWithContentsOfURL:[NSBundle mainBundle].appStoreReceiptURL] != nil;

#ifdef APPTENTIVE_DEBUG
		_debugBuild = YES;
#endif
	}

	return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
	self = [super initWithCoder:coder];

	if (self) {
		_type = [coder decodeObjectOfClass:[NSString class] forKey:TypeKey];
		_version = [coder decodeObjectOfClass:[ApptentiveVersion class] forKey:VersionKey];
		_build = [coder decodeObjectOfClass:[ApptentiveVersion class] forKey:BuildKey];
		_hasAppStoreReceipt = [coder decodeBoolForKey:HasAppStoreReceiptKey];
		_debugBuild = [coder decodeBoolForKey:DebugBuildKey];
		_overridingStyles = [coder decodeBoolForKey:OverridingStylesKey];
		
		_updateVersion = [coder decodeBoolForKey:UpdateVersionKey];
		_updateBuild = [coder decodeBoolForKey:UpdateBuildKey];

		_timeAtInstallTotal = [coder decodeObjectOfClass:[NSDate class] forKey:TimeAtInstallTotalKey];
		_timeAtInstallVersion = [coder decodeObjectOfClass:[NSDate class] forKey:TimeAtInstallVersionKey];
		_timeAtInstallBuild = [coder decodeObjectOfClass:[NSDate class] forKey:TimeAtInstallBuildKey];
	}

	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
	[super encodeWithCoder:coder];

	[coder encodeObject:self.type forKey:TypeKey];
	[coder encodeObject:self.version forKey:VersionKey];
	[coder encodeObject:self.build forKey:BuildKey];
	[coder encodeBool:self.hasAppStoreReceipt forKey:HasAppStoreReceiptKey];
	[coder encodeBool:self.debugBuild forKey:DebugBuildKey];
	[coder encodeBool:self.overridingStyles forKey:OverridingStylesKey];

	[coder encodeBool:self.updateVersion forKey:UpdateVersionKey];
	[coder encodeBool:self.updateBuild forKey:UpdateBuildKey];

	[coder encodeObject:self.timeAtInstallTotal forKey:TimeAtInstallTotalKey];
	[coder encodeObject:self.timeAtInstallVersion forKey:TimeAtInstallVersionKey];
	[coder encodeObject:self.timeAtInstallBuild forKey:TimeAtInstallBuildKey];
}

- (instancetype)initAndMigrate {
	self = [super init];

	if (self) {
		NSString * const ATConversationLastUpdateValuePreferenceKey = @"ATConversationLastUpdateValuePreferenceKey";

		NSDictionary *lastConversationUpdate = [[NSUserDefaults standardUserDefaults] objectForKey:ATConversationLastUpdateValuePreferenceKey];
		NSDictionary *appRelease = lastConversationUpdate[@"app_release"];

		_type = appRelease[@"type"];
		_version = [[ApptentiveVersion alloc] initWithString:appRelease[@"version"] ?: appRelease[@"cf_bundle_short_version_string"]];
		_build = [[ApptentiveVersion alloc] initWithString:appRelease[@"build"] ?: appRelease[@"cf_bundle_version"]];
		_hasAppStoreReceipt = [appRelease[@"app_store_receipt"][@"has_receipt"] boolValue];
		_debugBuild = [appRelease[@"debug"] boolValue];
		_overridingStyles = [appRelease[@"overriding_styles"] boolValue];

		_updateVersion = YES;
		_updateBuild = YES;

		_timeAtInstallTotal = [[NSUserDefaults standardUserDefaults] objectForKey:@"ATEngagementInstallDateKey"];
		_timeAtInstallVersion = [[NSUserDefaults standardUserDefaults] objectForKey:@"ATEngagementUpgradeDateKey"];
		_timeAtInstallBuild = [[NSUserDefaults standardUserDefaults] objectForKey:@"ATEngagementUpgradeDateKey"];
	}

	return self;
}

+ (void)deleteMigratedData {
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"ATConversationLastUpdateValuePreferenceKey"];
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"ATEngagementInstallDateKey"];
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"ATEngagementUpgradeDateKey"];
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"ATEngagementLastUsedVersionKey"];
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"ATEngagementIsUpdateVersionKey"];
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"ATEngagementIsUpdateBuildKey"];
}

- (void)resetVersion {
	_updateVersion = YES;
	_timeAtInstallVersion = [NSDate date]; // TODO: Inject as dependency?
}

- (void)resetBuild {
	_updateBuild = YES;
	_timeAtInstallBuild = [NSDate date]; // TODO: Inject as dependency?
}

- (void)setOverridingStyles {
	_overridingStyles = YES;
}

@end

@implementation ApptentiveAppRelease (JSON)

- (NSDictionary *)appStoreReceiptDictionary {
	return @{ @"has_receipt": @(self.hasAppStoreReceipt) };
}

- (NSString *)versionString {
	return self.version.versionString;
}

- (NSString *)buildString {
	return self.build.versionString;
}

- (NSNumber *)boxedDebugBuild {
	return @(self.debugBuild);
}

- (NSNumber *)boxedOverridingStyles {
	return @(self.overridingStyles);
}

+ (NSDictionary *)JSONKeyPathMapping {
	return @{
		@"type": NSStringFromSelector(@selector(type)),
		@"cf_bundle_short_version_string": NSStringFromSelector(@selector(versionString)),
		@"cf_bundle_version": NSStringFromSelector(@selector(buildString)),
		@"app_store_receipt": NSStringFromSelector(@selector(appStoreReceiptDictionary)),
		@"debug": NSStringFromSelector(@selector(boxedDebugBuild)),
		@"overriding_styles": NSStringFromSelector(@selector(boxedOverridingStyles))
	};
}

@end
