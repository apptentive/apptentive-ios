//
//  ApptentiveAppRelease.m
//  Apptentive
//
//  Created by Frank Schmitt on 11/15/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveAppRelease.h"
#import "ApptentiveVersion.h"

NS_ASSUME_NONNULL_BEGIN

static NSString *const TypeKey = @"type";
static NSString *const VersionKey = @"version";
static NSString *const BuildKey = @"build";
static NSString *const HasAppStoreReceiptKey = @"hasAppStoreReceipt";
static NSString *const DebugBuildKey = @"debugBuild";
static NSString *const OverridingStylesKey = @"overridingStyles";
static NSString *const UpdateVersionKey = @"updateVersion";
static NSString *const UpdateBuildKey = @"updateBuild";
static NSString *const TimeAtInstallTotalKey = @"timeAtInstallTotal";
static NSString *const TimeAtInstallVersionKey = @"timeAtInstallVersion";
static NSString *const TimeAtInstallBuildKey = @"timeAtInstallBuild";
static NSString *const CompilerKey = @"compiler";
static NSString *const PlatformBuildKey = @"platformBuild";
static NSString *const PlatformNameKey = @"platformName";
static NSString *const PlatformVersionKey = @"platformVersion";
static NSString *const SDKBuildKey = @"SDKBuild";
static NSString *const SDKNameKey = @"SDKName";
static NSString *const XcodeKey = @"Xcode";
static NSString *const XcodeBuildKey = @"XcodeBuild";

// Legacy keys
static NSString *const ATConversationLastUpdateValuePreferenceKey = @"ATConversationLastUpdateValuePreferenceKey";
static NSString *const ATEngagementInstallDateKey = @"ATEngagementInstallDateKey";
static NSString *const ATEngagementUpgradeDateKey = @"ATEngagementUpgradeDateKey";
static NSString *const ATEngagementLastUsedVersionKey = @"ATEngagementLastUsedVersionKey";
static NSString *const ATEngagementIsUpdateVersionKey = @"ATEngagementIsUpdateVersionKey";
static NSString *const ATEngagementIsUpdateBuildKey = @"ATEngagementIsUpdateBuildKey";


@implementation ApptentiveAppRelease

- (instancetype)init {
	self = [super init];

	if (self) {
		_updateVersion = NO;
		_updateBuild = NO;

		_timeAtInstallTotal = [NSDate date];   // TODO: Inject as dependency?
		_timeAtInstallVersion = [NSDate date]; // TODO: Inject as dependency?
		_timeAtInstallBuild = [NSDate date];   // TODO: Inject as dependency?
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

		_compiler = [NSBundle mainBundle].infoDictionary[@"DTCompiler"];
		_platformBuild = [NSBundle mainBundle].infoDictionary[@"DTPlatformBuild"];
		_platformName = [NSBundle mainBundle].infoDictionary[@"DTPlatformName"];
		_platformVersion = [NSBundle mainBundle].infoDictionary[@"DTPlatformVersion"];
		_SDKBuild = [NSBundle mainBundle].infoDictionary[@"DTSDKBuild"];
		_SDKName = [NSBundle mainBundle].infoDictionary[@"DTSDKName"];
		_Xcode = [NSBundle mainBundle].infoDictionary[@"DTXcode"];
		_XcodeBuild = [NSBundle mainBundle].infoDictionary[@"DTXcodeBuild"];


#ifdef APPTENTIVE_DEBUG
		_debugBuild = YES;
#endif
	}

	return self;
}

- (nullable instancetype)initWithCoder:(NSCoder *)coder {
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

		_compiler = [coder decodeObjectOfClass:[NSString class] forKey:CompilerKey];
		_platformBuild = [coder decodeObjectOfClass:[NSString class] forKey:PlatformBuildKey];
		_platformName = [coder decodeObjectOfClass:[NSString class] forKey:PlatformNameKey];
		_platformVersion = [coder decodeObjectOfClass:[NSString class] forKey:PlatformVersionKey];
		_SDKBuild = [coder decodeObjectOfClass:[NSString class] forKey:SDKBuildKey];
		_SDKName = [coder decodeObjectOfClass:[NSString class] forKey:SDKNameKey];
		_Xcode = [coder decodeObjectOfClass:[NSString class] forKey:XcodeKey];
		_XcodeBuild = [coder decodeObjectOfClass:[NSString class] forKey:XcodeBuildKey];
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

	[coder encodeObject:self.compiler forKey:CompilerKey];
	[coder encodeObject:self.platformBuild forKey:PlatformBuildKey];
	[coder encodeObject:self.platformName forKey:PlatformNameKey];
	[coder encodeObject:self.platformVersion forKey:PlatformVersionKey];
	[coder encodeObject:self.SDKBuild forKey:SDKBuildKey];
	[coder encodeObject:self.SDKName forKey:SDKNameKey];
	[coder encodeObject:self.Xcode forKey:XcodeKey];
	[coder encodeObject:self.XcodeBuild forKey:XcodeBuildKey];
}

- (instancetype)initAndMigrate {
	self = [super init];

	if (self) {
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

		_timeAtInstallTotal = [[NSUserDefaults standardUserDefaults] objectForKey:ATEngagementInstallDateKey];
		_timeAtInstallVersion = [[NSUserDefaults standardUserDefaults] objectForKey:ATEngagementUpgradeDateKey];
		_timeAtInstallBuild = [[NSUserDefaults standardUserDefaults] objectForKey:ATEngagementUpgradeDateKey];
	}

	return self;
}

+ (void)deleteMigratedData {
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:ATConversationLastUpdateValuePreferenceKey];
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:ATEngagementInstallDateKey];
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:ATEngagementUpgradeDateKey];
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:ATEngagementLastUsedVersionKey];
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:ATEngagementIsUpdateVersionKey];
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:ATEngagementIsUpdateBuildKey];
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

- (void)updateMissingTimeAtInstallTo:(NSDate *)timeAtInstall {
	_timeAtInstallTotal = _timeAtInstallTotal ?: timeAtInstall;
	_timeAtInstallVersion = _timeAtInstallVersion ?: timeAtInstall;
	_timeAtInstallBuild = _timeAtInstallBuild ?: timeAtInstall;
}

- (void)copyNonholonomicValuesFrom:(ApptentiveAppRelease *)otherAppRelease {
	_overridingStyles = otherAppRelease.overridingStyles;

	_timeAtInstallTotal = otherAppRelease.timeAtInstallTotal;
	_timeAtInstallVersion = otherAppRelease.timeAtInstallVersion;
	_timeAtInstallBuild = otherAppRelease.timeAtInstallBuild;

	_updateVersion = otherAppRelease.updateVersion;
	_updateBuild = otherAppRelease.updateBuild;
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
		@"overriding_styles": NSStringFromSelector(@selector(boxedOverridingStyles)),
		@"dt_compiler": NSStringFromSelector(@selector(compiler)),
		@"dt_platform_build": NSStringFromSelector(@selector(platformBuild)),
		@"dt_platform_name": NSStringFromSelector(@selector(platformName)),
		@"dt_platform_version": NSStringFromSelector(@selector(platformVersion)),
		@"dt_sdk_build": NSStringFromSelector(@selector(SDKBuild)),
		@"dt_sdk_name": NSStringFromSelector(@selector(SDKName)),
		@"dt_xcode": NSStringFromSelector(@selector(Xcode)),
		@"dt_xcode_build": NSStringFromSelector(@selector(XcodeBuild))
	};
}

@end

NS_ASSUME_NONNULL_END
